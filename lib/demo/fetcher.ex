defmodule Demo.Fetcher do
  @callback fetch() :: {:ok, integer()} | :error
end
