import Config

config :quiz, QuizWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  server: true,
  secret_key_base: String.duplicate("quiz-development-secret-", 3)
