import Config

if config_env() == :prod do
  config :quiz, QuizWeb.Endpoint, secret_key_base: System.fetch_env!("SECRET_KEY_BASE")
end
