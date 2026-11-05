# elixir-quiz-lab

A real-time multiplayer quiz built with Elixir, Phoenix, and LiveView.

## Run locally

Install Elixir and Erlang, then run:

```sh
mix deps.get
mix phx.server
```

Open [http://localhost:4000](http://localhost:4000) and create a room as the
host. Participants open `/join`, enter the room code and a name, and wait for
the host to start. Each of the five questions has a 20-second timer; answers
update the shared scoreboard immediately. Quiz rooms are held in memory and
are cleared when the server restarts.

Run the tests with `mix test`.
