defmodule Demo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    fetch_mod = Application.get_env(:demo, :fetch_mod)

    children = [
      {Demo.RandomInts, fetch_mod: fetch_mod}
    ]

    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
