defmodule Quiz.MixProject do
  use Mix.Project

  def project do
    [
      app: :quiz,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Quiz.Application, []},
      extra_applications: [:crypto, :logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:bandit, "~> 1.6"},
      {:jason, "~> 1.4"},
      {:phoenix, "~> 1.7.21"},
      {:phoenix_live_view, "~> 1.0.17"}
    ]
  end
end
