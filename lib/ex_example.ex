defmodule ExExample do
  @moduledoc """
  Documentation for `ExExample`.
  """
  alias ExExample.Analyze
  alias ExExample.Executor

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)

      # module attribute that holds all the examples
      Module.register_attribute(__MODULE__, :example_dependencies, accumulate: true)
      Module.register_attribute(__MODULE__, :examples, accumulate: true)
      Module.register_attribute(__MODULE__, :copies, accumulate: true)
      Module.register_attribute(__MODULE__, :copy, accumulate: false)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc """
      I return a list of all the dependencies for a given example,
      or the list of all dependencies if no argument is given.
      """
      def __example_dependencies__, do: @example_dependencies

      def __example_dependencies__(dependee) do
        @example_dependencies
        |> Enum.find({nil, []}, fn {name, _} -> name == dependee end)
        |> elem(1)
      end

      @doc """
      I reutrn all the examples in this module.
      """
      def __examples__ do
        @examples
      end

      @doc """
      I run all the examples in this module.
      """
      def __run_examples__ do
        __sorted__()
        |> Enum.each(fn {module, name} ->
          apply(module, name, [])
        end)
      end

      @doc """
      I return a topologically sorted list of examples.
      This list is the order in which the examples should be run.
      """
      @spec __sorted__() :: list({atom(), atom()})
      def __sorted__ do
        __example_dependencies__()
        |> Enum.reduce(Graph.new(), fn
          {example, []}, g ->
            Graph.add_vertex(g, {__MODULE__, example})

          {example, dependencies}, g ->
            dependencies
            # filter out all non-example dependencies
            |> Enum.filter(&Executor.example?/1)
            |> Enum.reduce(g, fn {{module, func}, _arity}, g ->
              Graph.add_edge(g, {module, func}, {__MODULE__, example})
            end)
        end)
        |> Graph.topsort()
      end

      def __example_copy__(example_name) do
        @copies
        |> Keyword.get(example_name, nil)
      end
    end
  end

  defmacro example({example_name, context, args} = name, do: body) do
    called_functions = Analyze.extract_function_calls(body, __CALLER__)

    # example_name is the name of the function that is being tested
    # e.g., `example_name`

    # hidden_func_name is the name of the hidden function that is being tested
    # this will contain the actual body of the example
    # __example_name__
    hidden_example_name = String.to_atom("__#{example_name}__")

    quote do
      # fetch the attribute value, and then clear it for the next examples.
      example_copy_tag = Module.get_attribute(unquote(__CALLER__.module), :copy)
      Module.delete_attribute(unquote(__CALLER__.module), :copy)

      def unquote({hidden_example_name, context, args}) do
        unquote(body)
      end

      @copies {unquote(example_name), {unquote(__CALLER__.module), example_copy_tag}}
      @example_dependencies {unquote(example_name), unquote(called_functions)}
      @examples unquote(example_name)
      def unquote(name) do
        example_dependencies = __example_dependencies__(unquote(example_name))
        example_copy = __example_copy__(unquote(example_name))

        Executor.maybe_run_example(__MODULE__, unquote(example_name), example_dependencies,
          copy: example_copy
        )
      end
    end
  end
end
