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

  @doc """
  I create a graph of examples and topologically sort them.
  """
  def dependency_graph(examples) do
    examples
    |> Enum.reduce(Graph.new(), fn example, g ->
      {mod, func, deps} = example

      if deps == nil do
        Graph.add_vertex(g, {mod, func})
      else
        Enum.reduce(deps, g, &Graph.add_edge(&2, {mod, &1}, {mod, func}))
      end
    end)
  end

  @doc """
  I run the given list of examples.

  An example is in the form of {module, function, dependencies}
  """
  def run_examples(examples, dependencies) do
    examples
    |> Enum.reduce_while(%{}, fn example, eval_results ->
      # list all dependencies for this example
      example_deps =
        Graph.in_edges(dependencies, example)
        |> Enum.map(&Map.get(&1, :v1))

      # get the input values from the runs of the examples this one depends on
      inputs = Enum.map(example_deps, &{&1, Map.get(eval_results, &1)})

      failed_inputs = Enum.filter(inputs, &Map.get(elem(&1, 1), :failed?, false))
      skipped_inputs = Enum.filter(inputs, &Map.get(elem(&1, 1), :skipped?, false))

      # if any of its dependencies failed, this example will be skipped.
      if not Enum.empty?(failed_inputs) or not Enum.empty?(skipped_inputs) do
        {:cont,
         Map.put(eval_results, example, %{
           skipped?: true,
           skipped_inputs: skipped_inputs,
           failed_inputs: failed_inputs
         })}
      else
        inputs = Enum.map(inputs, &Map.get(elem(&1, 1), :result))

        case run_example(example, inputs) do
          {:ok, result} ->
            {:cont, Map.put(eval_results, example, %{result: result, failed?: false})}

          {:error, e} ->
            {:cont, Map.put(eval_results, example, %{error: e, failed?: true})}
        end
      end
    end)
  end

  def run_example({module, function}, inputs) do
    try do
      result = apply(module, function, inputs)
      {:ok, result}
    rescue
      e ->
        {:error, e}
    end
  end

  def print_result(result) do
    for {{_, func}, output} <- result do
      case output do
        %{failed?: true} ->
          IO.puts("""
          🔴 #{inspect(func)}
             error: #{inspect(Map.get(output, :error, nil))}
          """)

        %{skipped?: true} ->
          skipped_inputs =
            Enum.map(Map.get(output, :skipped_inputs, []), &(&1 |> elem(0) |> elem(1)))

          failed_inputs =
            Enum.map(Map.get(output, :failed_inputs, []), &(&1 |> elem(0) |> elem(1)))

          IO.puts("⚪️ #{inspect(func)}")

          if skipped_inputs != [] do
            IO.puts("   skipped inputs: #{inspect(skipped_inputs)}")
          end

          if failed_inputs != [] do
            IO.puts("   failed inputs: #{inspect(failed_inputs)}")
          end

        %{failed?: false, result: r} ->
          IO.puts("🟢 #{inspect(func)}\n   result: #{inspect(r)}\n")
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def debug() do
        # Create a graph of dependencies between the examples
        dependencies = ExExample.dependency_graph(@test)

        # Create a list for the order of evaluation of the examples
        eval_order = Graph.topsort(dependencies)

        # Evaluate the list
        result = ExExample.run_examples(eval_order, dependencies)

        result
        |> ExExample.print_result()

        nil
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
