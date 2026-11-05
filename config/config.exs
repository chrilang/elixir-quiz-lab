import Config

config :quiz, QuizWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  live_view: [signing_salt: "quizlab"],
  pubsub_server: Quiz.PubSub,
  render_errors: [formats: [html: QuizWeb.ErrorHTML], layout: false]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
