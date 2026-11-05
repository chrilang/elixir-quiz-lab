import Config

config :quiz, QuizWeb.Endpoint,
  server: false,
  secret_key_base: String.duplicate("quiz-test-secret-", 4)
