defmodule ExExample.Executor do
  @moduledoc """
  I contain functionality to execute examples.

  I contain logic to determine if a cachd result should be used, computation should be done again,
  or if an example should be skipped.
  """
  alias ExExample.Cache

  require Logger
  @type dependency :: {{atom(), atom()}, non_neg_integer()}

  @doc """
  I determine if a module/function pair is an example or not.

  A function is an example if it is defined in a module that has the `__examples__/0` function
  implemented, and when the `__examples__()` output lists that function name as being an example.
  """
  @spec example?(dependency) :: boolean()
  def example?({{module, func}, _arity}) do
    {:__examples__, 0} in module.__info__(:functions) and func in module.__examples__()
  end

  @doc """
  Given an example, I return a hash of all its dependencies.
  This hash can be used to determine of an example was run with
  an older version of a dependency.
  """
  def deps_hash(dependencies) do
    dependencies
    |> Enum.map(fn {{module, _func}, _arity} ->
      module.__info__(:attributes)[:vsn]
    end)
    |> :erlang.phash2()
  end

  @doc """
  I run an example, iff all its dependencies have succeeded.

  If all the dependencies of this example executed succesfully,
  I will execute the example.

  If any of the example its dependencies either failed or were skipped,
  I will skip the example.
  """
  @spec maybe_run_example(atom(), atom(), list(dependency)) :: any()
  def maybe_run_example(module, func, dependencies) do
    dependency_results =
      dependencies
      |> Enum.map(fn {{module, func}, _arity} ->
        Cache.state({module, func})
      end)
      |> Enum.group_by(& &1)
      |> Map.put_new(:success, [])
      |> Map.put_new(:skipped, [])
      |> Map.put_new(:failed, [])

    deps_hash = deps_hash(dependencies)

    case dependency_results do
      %{success: _, failed: [], skipped: []} ->
        # check for a cached result
        case Cache.get_result(%Cache.Key{module: module, function: func, deps_hash: deps_hash}) do
          # cached result, no recompile
          {:ok, result} ->
            Logger.debug("found cached result for #{inspect(module)}.#{func}")
            result.result

          {:error, :no_result} ->
            Logger.debug("running #{inspect(module)}.#{func} for the first time")
            hidden_example_name = String.to_atom("__#{func}__")

            run_example(module, hidden_example_name, [], func, deps_hash)
            |> Map.get(:result)
        end

      map ->
        Logger.warning(
          "skipping #{inspect(module)}.#{func} due to failed or skipped dependencies"
        )

        {:error, :skipped_or_failed, map}
    end
  end

  # @doc """
  # I run an example in a module and wrap its output in
  # something that can be cached.
  # """
  @spec run_example(atom(), atom(), list(term()), atom(), any()) :: Cache.Result.t()
  defp run_example(module, func, arguments, example_name, deps_hash) do
    key = %Cache.Key{
      module: module,
      function: example_name,
      arguments: arguments,
      deps_hash: deps_hash
    }

    result =
      try do
        %Cache.Result{key: key, success: :success, result: apply(module, func, [])}
      rescue
        e ->
          Logger.error(inspect(e))
          %Cache.Result{key: key, success: :failed, result: e}
      end

    # put the result of this invocation in the cache.
    Cache.put_result(result, key)

    result
  end
end
