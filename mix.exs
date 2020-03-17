defmodule PrxClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :prx_client,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_machina, "~> 2.3", only: :test},
      {:fake_server, "~> 2.1", only: :test},
      {:httpoison, "~> 1.6"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:oauth2, "~> 2.0"},
      {:poison, "~> 3.1"},
      {:uri_template, "~> 1.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
