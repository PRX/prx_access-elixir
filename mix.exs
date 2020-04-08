defmodule PrxAccess.MixProject do
  use Mix.Project

  def project do
    [
      app: :prx_access,
      version: "0.2.0",
      elixir: "~> 1.6",
      name: "PrxAccess",
      source_url: "https://github.com/PRX/prx_access-elixir",
      homepage_url: "https://github.com/PRX/prx_access-elixir",
      description: description(),
      package: package(),
      docs: docs(),
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_machina, "~> 2.3", only: :test},
      {:fake_server, "~> 2.1", only: :test},
      {:httpoison, "~> 1.6"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:oauth2, "~> 2.0"},
      {:poison, ">= 2.0.0"},
      {:uri_template, ">= 1.0.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    "Client library for accessing PRX APIs"
  end

  defp package do
    [
      contributors: ["Ryan Cavis"],
      maintainers: ["Ryan Cavis"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/PRX/prx_access-elixir"},
      files: ~w(lib LICENSE mix.exs README.md)
    ]
  end

  defp docs do
    [main: "readme", extras: ["README.md"]]
  end
end
