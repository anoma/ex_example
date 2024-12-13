defmodule ExExample.Cache do
  @moduledoc """
  I define logic to store and retrieve results from the cache.
  """

  alias ExExample.Cache.Key
  alias ExExample.Cache.Result

  require Logger

  @cache_name __MODULE__

  @doc """
  I clear the entire cache.
  """
  @spec clear() :: :ok
  def clear do
    Cachex.clear!(@cache_name)
    :ok
  end

  @doc """
  I store a result in cache for a given key.
  """
  @spec put_result(Result.t(), Key.t()) :: {atom(), boolean()}
  def put_result(%Result{} = result, %Key{} = key) do
    Cachex.put(@cache_name, key, result)
  end

  @doc """
  I fetch a previous Result from the cache if it exists.
  If it does not exist, I return `{:error, :not_found}`.
  """
  @spec get_result(Key.t()) :: {:ok, Result.t()} | {:error, :no_result}
  def get_result(%Key{} = key) do
    case Cachex.get(@cache_name, key) do
      {:ok, nil} ->
        {:error, :no_result}

      {:ok, result} ->
        {:ok, result}
    end
  end

  @doc """
  I return the state of the last execution of an example.
  """
  @spec state(Key.t() | {atom(), atom()}) :: :succeeded | :failed | :skipped
  def state({module, function}) do
    state(%Key{module: module, function: function})
  end

  def state(%Key{} = key) do
    case Cachex.get(@cache_name, key) do
      {:ok, nil} ->
        nil

      {:ok, result} ->
        result.success
    end
  end
end
