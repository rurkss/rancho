defmodule Rancho.MixProject do
  use Mix.Project

  def project do
    [
      app: :rancho,
      version: System.get_env("RELEASE_VERSION") || "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ranch, :cowboy, :plug, :prometheus_ex, :httpotion],
      mod: {Rancho.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ranch, "~> 1.7"},
      {:distillery, "~> 2.0"},
      {:prometheus, "~> 4.0", override: true},
      {:prometheus_ex, "~> 3.0"},
      {:prometheus_process_collector, "~> 1.4"},
      {:cowboy, "~> 2.6.1"},
      {:plug, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"},
      {:jiffex, "~> 0.2.0"},
      {:redix, "~> 0.10.1"},
      {:httpotion, "~> 3.1.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
