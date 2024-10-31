defmodule ExExample.Cache do
  @moduledoc """
  I define logic to store and retrieve results from the cache.
  """
  alias ExExample.Cache.Key
  alias ExExample.Cache.Result

  require Logger

  @cache_name :ex_examples

  @doc """
  I store a result in cache for a given key.
  """
  @spec store_result(Result.t(), Key.t()) :: {atom(), boolean()}
  def store_result(%Result{} = result, %Key{} = key) do
    Logger.debug("store result for #{inspect(key)}: #{inspect(result)}")
    Cachex.put(@cache_name, key, result)
  end

  @doc """
  I fetch a previous Result from the cache if it exists.
  If it does not exist, I return `{:error, :not_found}`.
  """
  @spec get_result(Key.t()) :: {:ok, any()} | {:error, :no_result}
  def get_result(%Key{} = key) do
    case Cachex.get(@cache_name, key) do
      {:ok, nil} ->
        Logger.debug("cache miss for #{inspect(key)}")
        {:error, :no_result}

      {:ok, result} ->
        Logger.debug("cache hit for #{inspect(key)}")
        {:ok, result}
    end
  end
end
