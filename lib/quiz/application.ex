defmodule Quiz.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Quiz.PubSub},
      Quiz.Rooms,
      QuizWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Quiz.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    QuizWeb.Endpoint.config_change(changed, removed)
  end
end
