defmodule ExExample.Execute do
  @moduledoc """
  I define logic to execute the code of an example.

  I am responsible for checking the cache for the result of an example, and if it is not found,
  I execute the example and store the result in the cache.
  """
  alias ExExample.Analyze
  alias ExExample.Cache
  alias ExExample.Cache.Key
  alias ExExample.Cache.Result

  require Logger

  @doc """
  I execute an example with the given arguments.

  If the example has been ran before with the given arguments, the cached result is returned.
  If not, the example is executed and the result is stored in the cache.
  """
  @spec execute_example(Key.t(), list(any())) :: any()
  def execute_example(%Key{} = key, args) do
    Logger.debug("execute #{inspect(key)} with #{inspect(args)}")

    case Cache.get_result(key) do
      {:error, :no_result} ->
        execute_no_cache(key, args)

      {:ok, result} ->
        # check the rerun?/1 callback whether or not a rerun is required
        if must_rerun?(key, result) do
          Logger.debug("must rerun example")
          execute_no_cache(key, args)
        else
          make_copy(key, result)
          |> Map.get(:result)
        end
    end
  end

  @doc """
  I execute the example without using the cache.

  I store the result in cache, and then return the computed result of the example.
  """
  @spec execute_no_cache(Key.t(), list(any())) :: any()
  def execute_no_cache(%Key{} = key, args) do
    Logger.debug("execute #{inspect(key)} no cache")

    # call the no_cache version of the example to compute the result.
    no_cache_name = String.to_atom("#{key.name}_no_cache")
    res = apply(key.module, no_cache_name, args)

    # update the key with the latest hash of the dependencies
    key = %{key | deps_hash: Analyze.dependencies_hash(key.module)}

    # store the result in cache
    result = %Result{result: res, key: key}
    Cache.store_result(result, key)

    # return the result from the example
    result.result
  end

  # ----------------------------------------------------------------------------
  # Helpers

  # @doc """
  # I make a copy of the result and return that, instead of the cached one.
  # """
  defp make_copy(%Key{} = key, %Result{} = result) do
    key.module.copy(result)
  end

  # @doc """
  # I check if the given key must be rerun.
  # A re-run can be caused by changed dependencies, or if the example defined rerun? to return true.
  # """
  defp must_rerun?(%Key{} = key, %Result{} = result) do
    key.module.rerun?(result) or any_files_recompiled?(key)
  end

  # @doc """
  # I check if the given key has any dependencies that have changed.
  # """
  defp any_files_recompiled?(%Key{} = key) do
    Analyze.dependencies_hash(key.module) != key.deps_hash
  end
end
