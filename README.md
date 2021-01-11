# A GenServer cheat sheet

This README describes what GenServers are and some things they can be useful for. The repo serves as an annotated cheat sheet of "best practices" around using one in an elixir application.

# What is a GenServer

A [GenServer](https://hexdocs.pm/elixir/GenServer.html#content) is an Elixir process that can maintain some state and has a well-defined contract for receiving messages from other processes and responding to them.

GenServers are workhorses of the Elixir world, and are used extensively. I like to think of them as little "bags of state" sitting "over there" doing their own thing, that the rest of your code can periodically ask questions of.

# What are GenServers used for?

GenServers are useful for many things. In my experience I've created GenServers primarily for the following uses:

## Little in memory "mini-DBs".

GenServers can maintain their own state. They can also be given a name when they start up, which makes it easy for code and processes throughout your app to ask them things. In the example below, `FavoriteNumbers` is a GenServer exposing an interface that lets clients manipulate its state in defined ways, as well as query that state.

```ex
iex> FavoriteNumbers.reset()
[]
iex> FavoriteNumbers.add(5)
5
iex> FavoriteNumbers.add(7)
7
iex> FavoriteNumbers.all()
[5, 7]
iex> FavoriteNumbers.is_favorite?(7)
true
iex> FavoriteNumbers.is_favorite?(11)
false
```

At the MBTA, some examples of GenServers serving this function, are ones that keep track of where subway vehicles are and ones that keep track of what's on the countdown clocks at stations.

## Recurring processes

GenServers are great to use with `:timer.send_interval/3`, which sends a process a message on a repeated basis. In this case, the GenServer is the stand alone process, and it also effectively sends *itself* messages every so often, rather than simply being there to respond to other processes.

At the MBTA, some examples of this usage are periodic downloading of files or hourly calculation of accuracy metrics.

## Inducing an ordering of operations

One of the challenges of Elixir's model of distributed processes, is that they're conceptually all working concurrently. Since a GenServer responds to messages in the order it receives them, they can be used to induce an ordering in other processes. However, this also is then a potential bottleneck.

In practice, I have used GenServers for this purpose less frequently. One case that comes to mind is using them as something of a "worker pool". For example, in the aforementioned example of GenServers representing the state of each sign in the system, each of them wants to send an HTTP POST to our vendor to update the physical hardware. But in order to not, essentially, DDOS the vendor, we have all the signs send through a single GenServer, which rate limits itself and builds up a small queue, since sign updates can be "bursty".

# Best practices with using GenServers

This repo is an annotated example of adding a single GenServer into the supervision tree and testing it. Some things to note are:

* All GenServers must always live in the Supervision tree.
* We like to use `defstruct` in each GenServer to hold its state.
* Most useful GenServers will need some level of dependency injection. We typically DI via configuration options when the GenServer starts up, and store that in the GenServer's state. We DI via a module, which can then have a `@behaviour` defined.

# "Gotchas" to watch out for

The biggest thing to watch out for is the GenServer timing out. If a process calls `MyGenServer.do_a_thing()`, then that process will wait for a while (default of 5 seconds) before timing out and blowing up. Importantly, a GenServer answers messages in the order it receives them, so if a GenServer's `handle_call/3` callback is too slow relative to the number of requets it gets, the mailbox can backup and eventually calling processes can time out. This is "backpressure" and sometimes necessary.

One situation that has caused us trouble before is when a GenServer is used *both* in the "recurring process" sense (perhaps fetching some data from a URL every so often) *and* a "mini DB" sense, answering questions about that state from other processes. In that situation, HTTP requests can take a couple seconds or more, and so while the GenServer is doing that (if it's part of the `handle_info` callback), "mini DB" type requests will back up. We've fixed this in the past by introducing *another* process that actually does the download and then sends a message to the GenServer once it's complete, with the data, so the GenServer isn't blocked while waiting on the request.
