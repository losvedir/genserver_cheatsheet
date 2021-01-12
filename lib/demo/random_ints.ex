defmodule Demo.RandomInts do
  use GenServer
  require Logger

  @enforce_keys [:fetch_mod]
  defstruct @enforce_keys ++
              [
                ints: []
              ]

  @type state :: %__MODULE__{
          fetch_mod: module(),
          ints: [integer()]
        }

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec seen_number?(GenServer.server(), integer()) :: boolean()
  def seen_number?(pid \\ __MODULE__, n) do
    GenServer.call(pid, {:seen_number?, n})
  end

  def init(args) do
    fetch_mod = Keyword.fetch!(args, :fetch_mod)
    repeat_ms = Keyword.get(args, :repeat_ms, 1000)

    :timer.send_interval(repeat_ms, self(), :do_fetch)

    {:ok, %__MODULE__{fetch_mod: fetch_mod}}
  end

  def handle_call({:seen_number?, n}, _from, state) do
    {:reply, n in state.ints, state}
  end

  def handle_info(:do_fetch, state) do
    case state.fetch_mod.fetch() do
      {:ok, n} ->
        Logger.info("fetched #{n}")
        {:noreply, %{state | ints: [n | state.ints]}}

      :error ->
        Logger.warn("got an error this time")
        {:noreply, state}
    end
  end

  # If you ever specify a handle_info/2 callback (as with :do_fetch above), then you need to
  # also provide a catch-all for unexpected messages. Otherwise the GenServer will crash when
  # it receives one. If you don't specify a handle_info, then use GenServer will provide
  # a catch-all for you automatically.
  def handle_info(msg, state) do
    Logger.info("Received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end
