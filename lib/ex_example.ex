defmodule ExExample do
  @moduledoc """
  Documentation for `ExExample`.
  """
  alias ExExample.Analyze
  alias ExExample.Cache
  alias ExExample.Executor

  ############################################################
  #                       Types                              #
  ############################################################

  @typedoc """
  A dependency is a function that will be called by an example.
  The format of a dependency is `{{module, function}, arity}`
  """
  @type dependency :: {{atom(), atom()}, non_neg_integer()}

  @typedoc """
  """
  @type example :: {atom(), list(dependency)}

  ############################################################
  #                       Helpers                            #
  ############################################################

  @doc """
  I return the hidden name of an example.
  The hidden name is the example body without modification.
  """
  @spec hidden_name({atom(), atom()}) :: {atom(), atom()}
  def hidden_name({module, func}) do
    {module, String.to_atom("__#{func}__")}
  end

  @doc """
  I determine if a module/function pair is an example or not.

  A function is an example if it is defined in a module that has the `__examples__/0` function
  implemented, and when the `__examples__()` output lists that function name as being an example.
  """
  @spec example?(dependency()) :: boolean()
  def example?({{module, func}, _arity}) do
    example_module?(module) and Keyword.has_key?(module.__examples__(), func)
  end

  @doc """
  I return true if the given module contains examples.
  """
  @spec example_module?(atom()) :: boolean
  def example_module?(module) do
    {:__examples__, 0} in module.__info__(:functions)
  end

  @doc """
  I return a list of all dependencies for this example.
  Note: this does includes other called modules too (e.g., Enum).
  """
  @spec all_dependencies({atom(), atom()}) :: [dependency()]
  def all_dependencies({module, func}) do
    module.__examples__()
    |> Keyword.get(func, [])
  end

  @doc """
  I return a list of example dependencies for this example.
  Note: this does not include other called modules.
  """
  @spec example_dependencies({atom(), atom()}) :: [dependency()]
  def example_dependencies({module, func}) do
    all_dependencies({module, func})
    |> Enum.filter(&example?/1)
  end

  @doc """
  I return a list of examples in the order they should be
  executed in.

  I do this by topologically sorting their execution order.
  """
  @spec execution_order(atom()) :: [{atom(), atom()}]
  def execution_order(module) do
    module.__examples__()
    |> Enum.reduce(Graph.new(), fn
      {function, []}, g ->
        Graph.add_vertex(g, {__MODULE__, function})

      {function, dependencies}, g ->
        dependencies
        # filter out all non-example dependencies
        |> Enum.filter(&example?/1)
        |> Enum.reduce(g, fn {{module, func}, _arity}, g ->
          Graph.add_edge(g, {module, func}, {module, function})
        end)
    end)
    |> Graph.topsort()
  end

  ############################################################
  #                       Macros                             #
  ############################################################

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)

      @behaviour ExExample.Behaviour

      # module attribute that holds all the examples
      Module.register_attribute(__MODULE__, :examples, accumulate: true)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @spec __examples__ :: [ExExample.example()]
      def __examples__, do: @examples
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
      def unquote({hidden_example_name, context, args}) do
        unquote(body)
      end

      @examples {unquote(example_name), unquote(called_functions)}
      def unquote(name) do
        case Executor.attempt_example({__MODULE__, unquote(example_name)}, []) do
          %{result: %Cache.Result{success: :success} = result} ->
            result.result

          %{result: %Cache.Result{success: :failed} = result} ->
            raise result.result

          %{result: %Cache.Result{success: :skipped} = result} ->
            :skipped
        end
      end
    end
  end
end
