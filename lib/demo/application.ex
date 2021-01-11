defmodule Demo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # For injecting dependencies, better to do so at the Application level and
    # passing into the GenServer as a configuration option, to live in its state,
    # than to Application.get_env/2 all the time within the GenServer. This makes
    # it easier to test, and can accommodate async tests, since the global
    # Application state doesn't need to be changed for the test.
    #
    # Modules make for great dependencies to inject, since you can use a @behaviour
    # to ensure testing, prod, and dev injections conform to the same interface.
    fetch_mod = Application.get_env(:demo, :fetch_mod)

    children = [
      {Demo.RandomInts, fetch_mod: fetch_mod}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
