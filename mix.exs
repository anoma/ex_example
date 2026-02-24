defmodule ExExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_example,
      version: "0.1.1",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      dialyzer: [
        plt_add_deps: :apps_direct,
        plt_add_apps: [:ex_unit]
      ],
      # for docs
      name: "ExExample",
      source_url: "https://github.com/anoma/ex_example",
      homepage_url: "https://github.com/anoma/ex_example",
      docs: &docs/0
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ExExample.Application, []}
    ]
  end

  defp deps do
    [
      {:cachex, "~> 4.1.1"},
      {:libgraph, "~> 0.16.0"},
      {:typed_struct, "~> 0.3.0"},
      # non-runtime dependencies below
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.31", only: [:dev], runtime: false}
    ]
  end

  defp description do
    """
    An examples framework for Elixir. Examples are functions that
    return useful values, are callable from IEx, depend on and build
    upon each other, are cached with automatic invalidation, and
    double as ExUnit tests.
    """
  end

  defp package do
    [
      maintainers: [
        "mariari <mariari@protonmail.ch>",
        "Raymond E. Pasco <raymond@heliax.dev>"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/anoma/ex_example"
      },
      files: ~w(lib mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
