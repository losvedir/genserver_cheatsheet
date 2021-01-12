# where they're used. Be sure to specify the behaviour!
# Can define simple "Fake" DI modules in the same test file
defmodule FakeRandomIntsFetcher do
  @behaviour Demo.Fetcher

  def fetch(), do: {:ok, 5}
end

defmodule FakeRandomIntsErrorFetcher do
  @behaviour Demo.Fetcher

  def fetch(), do: :error
end

defmodule Demo.RandomIntsTest do
  use ExUnit.Case, async: true

  alias Demo.RandomInts

  @state %Demo.RandomInts{
    fetch_mod: FakeRandomIntsFetcher
  }

  describe "integration test" do
    test "starts up, can query before and after a fetch" do
      {:ok, pid} =
        RandomInts.start_link(name: :test1, fetch_mod: FakeRandomIntsFetcher, repeat_ms: 50)

      # We set repeat_ms to 50ms, so it hasn't run yet. Use our pid!
      refute RandomInts.seen_number?(pid, 5)

      # Sleep longer than 50ms, so the timer triggers
      Process.sleep(60)

      # Since we passed in fetch_mod: FakeRandomIntsFetcher we know we got a 5
      assert RandomInts.seen_number?(pid, 5)
    end
  end

  describe "seen_number?/1" do
    test "returns true if the number is in the state" do
      state = %{@state | ints: [10, 5]}
      assert {:reply, true, ^state} = RandomInts.handle_call({:seen_number?, 10}, self(), state)
    end

    test "returns false if the number is not in the state" do
      state = %{@state | ints: [10, 5]}
      assert {:reply, false, ^state} = RandomInts.handle_call({:seen_number?, 7}, self(), state)
    end
  end
end
