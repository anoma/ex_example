defmodule ExExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_example,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
end
