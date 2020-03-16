defmodule PrxClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :prx_client,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.6"},
      {:oauth2, "~> 2.0"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:mox, "~> 0.5", only: :test},
      {:poison, "~> 3.1"},
      {:uri_template, "~> 1.0"}
    ]
  end
end
