defmodule Demo.RandomInts do
  use GenServer
  require Logger

  # Every GenServer should define a struct for its state. The required keys should
  # be listed in @enforce_keys, which Elixir will use whenever a struct is constructed
  # to ensure such keys are present. In the `defstruct`, we also enumerate other,
  # optional, keys and possibly their default values.
  @enforce_keys [:fetch_mod]
  defstruct @enforce_keys ++
              [
                ints: []
              ]

  # Dialyzer should be used in all projects, and each GenServer should have a defined
  # type called state(), which is the struct of the module.
  @type state :: %__MODULE__{
          fetch_mod: module(),
          ints: [integer()]
        }

  # For simplicity, start_link/1 should take a single argument, `opts`, which can be
  # used to configure both the internal operation of the GenServer (i.e., the second
  # argument to GenServer.start_link/3, which gets passed to init/1) as well as the
  # "meta" operation of the GenServer (i.e.: the third argument to GenServer.start_link/3)
  # like its name and timeout.
  def start_link(opts) do
    # If this GenServer will be called by any other process, for example if it's serving
    # as a kind of mini-DB, using __MODULE__ as a default name is useful, so client
    # functions can omit the pid argument. However, name should always be a configurable
    # option so that tests can start up a GenServer with a distinct name.
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  ##### "Client" functions specified on top of file ####

  # Always write a @spec for client functions.
  @spec seen_number?(GenServer.server(), integer()) :: boolean()

  # The first argument for a client function, if it plans to be called elsewhere in the app
  # (i.e., it's not just a self contained timer loop or something), should be `pid \\ __MODULE__`,
  # so that elsewhere in the app, it can be invoked simply by RandomInts.seen_number?(5), but
  # so you can still test GenServers with other names.
  def seen_number?(pid \\ __MODULE__, n) do
    # The contents of client functions should be little more than simply invoking `GenServer.call/2`.
    # Note that any code here is executed by the *calling process*, and not the GenServer.
    GenServer.call(pid, {:seen_number?, n})
  end

  ##### "Server" callbacks are specified at the bottom of the file #####
  def init(args) do
    # Here in init/1 args are accessed for the state, all in one place. For
    # necessary arguments, it's good to use Keyword.fetch!/2. That way, if they're
    # missing, the GenServer will crash and the application will fail to start, making
    # it easier to see that a necessary argument was not passed in. For optional ones,
    # use Keyword.get/3 and provide a default value.
    fetch_mod = Keyword.fetch!(args, :fetch_mod)
    repeat_ms = Keyword.get(args, :repeat_ms, 1000)

    :timer.send_interval(repeat_ms, self(), :do_fetch)

    # Finally, the GenServer starts up, with a state struct for its state.
    {:ok, %__MODULE__{fetch_mod: fetch_mod}}
  end

  def handle_call({:seen_number?, n}, _from, state) do
    # In this case, the answer is straightforward enough that the code can reasonably be
    # included here. However, if the calculation is more complex, it's often better to have
    # another module of pure functions, leaving the state manipulation to the GenServer.
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
