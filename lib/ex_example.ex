defmodule ExExample do
  @moduledoc """
  I am the ExExample Application Module

  I startup the ExExample system as an OTP application. Moreover Ι
  provide all the API necessary for the user of the system. I contain
  all public functionality

  ### Public API
  """

  use Application

  def start(_type, args \\ []) do
    ExExample.Supervisor.start_link(args)
  end

  @doc """
  I am the use macro for ExExample.

  I import the ExExample.Behaviour module, expose the macros, and define the `copy/1` and `rerun?/1` callbacks.
  """
  defmacro __using__(_options) do
    quote do
      import unquote(ExExample.Macro)
      # module attribute that holds all the examples
      Module.register_attribute(__MODULE__, :examples, accumulate: true)
      Module.register_attribute(__MODULE__, :depends, accumulate: false)
      Module.register_attribute(__MODULE__, :test, accumulate: true)

      # import the behavior for the callbacks
      @behaviour ExExample.Behaviour

      # default implementation of the callbacks
      def copy(result) do
        result
      end

      def rerun?(_result) do
        false
      end

      # mark the callbacks are overridable.
      defoverridable copy: 1
      defoverridable rerun?: 1

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def debug() do
        deps =
          @test
          |> Enum.reduce(Graph.new(), fn dep, g ->
            {mod, example, deps} = dep

            if deps == nil do
              Graph.add_vertex(g, {mod, example})
            else
              deps
              |> Enum.reduce(g, &Graph.add_edge(&2, {mod, &1}, {mod, example}))
            end
          end)

        deps
        |> Graph.topsort()
        |> Enum.reduce_while(%{}, fn {mod, func} = example, acc ->
          deps = Graph.in_edges(deps, example)

          inputs =
            deps
            |> Enum.reduce([], fn edge, inputs ->
              %{v1: input_example} = edge
              [Map.get(acc, input_example) | inputs]
            end)

          try do
            result = apply(mod, func, inputs)
            {:cont, Map.put(acc, example, result)}
          rescue
            e ->
              {:halt, "example #{inspect(func)} failed"}
          end
        end)
      end

      def run_examples() do
        Enum.each(@examples, fn {example, deps} ->
          IO.inspect(deps, label: "deps")
          apply(__MODULE__, example, [])
        end)
      end
    end
  end
end
