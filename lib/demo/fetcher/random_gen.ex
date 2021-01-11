defmodule Demo.Fetcher.RandomGen do
  @behaviour Demo.Fetcher

  @impl Demo.Fetcher
  def fetch do
    num = floor(:rand.uniform() * 10)

    if num > 0 do
      {:ok, num}
    else
      :error
    end
  end
end
