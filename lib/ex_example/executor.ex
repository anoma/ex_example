defmodule ExExample.Executor do
  @moduledoc """
  I contain functionality to execute examples.

  I contain logic to determine if a cachd result should be used, computation should be done again,
  or if an example should be skipped.
  """

  require Logger

  alias ExExample.Cache
  alias ExExample.Run

  ############################################################
  #                       API                                #
  ############################################################

  @spec print_dependencies(ExExample.Run.t()) :: binary()
  def print_dependencies(run) do
    output =
      if run.success != [] do
        run.success
        |> Enum.map_join(
          ", ",
          fn {{mod, func}, _arity} -> "   🟢 #{inspect(mod)}.#{Atom.to_string(func)}" end
        )
      else
        ""
      end

    output =
      if run.failed != [] do
        run.success
        |> Enum.map_join(
          ", ",
          fn {{mod, func}, _arity} ->
            "    🔴 #{inspect(mod)}.#{Atom.to_string(func)}"
          end
        )
        |> Kernel.<>(output)
      else
        output
      end

    output =
      if run.no_cache != [] do
        run.success
        |> Enum.map_join(
          ", ",
          fn {{mod, func}, _arity} ->
            "    ⚪️ #{inspect(mod)}.#{Atom.to_string(func)}"
          end
        )
        |> Kernel.<>(output)
      else
        output
      end

    output =
      if run.skipped != [] do
        run.success
        |> Enum.map_join(
          ", ",
          fn {{mod, func}, _arity} ->
            "    ⚪️ #{inspect(mod)}.#{Atom.to_string(func)}"
          end
        )
        |> Kernel.<>(output)
      else
        output
      end

    if output == "", do: "", else: "\n" <> output
  end

  @spec print_run(ExExample.Run.t()) :: :ok
  def print_run(%Run{result: %Cache.Result{success: :success} = result} = run) do
    cached = if result.cached, do: "(cached) ", else: ""

    IO.puts("""
    🟢 #{cached}#{inspect(run.key.module)}.#{Atom.to_string(run.key.function)}\
       #{print_dependencies(run)}\
    """)

    :ok
  end

  def print_run(%Run{result: %Cache.Result{success: :skipped} = result} = run) do
    cached = if result.cached, do: "(cached) ", else: ""

    IO.puts("""
    ⚪️  #{cached}#{inspect(run.key.module)}.#{Atom.to_string(run.key.function)}\
       #{print_dependencies(run)}\
    """)

    :ok
  end

  def print_run(%Run{result: %Cache.Result{success: :failed} = result} = run) do
    cached = if result.cached, do: "(cached) ", else: ""

    IO.puts("""
    🔴  #{cached}#{inspect(run.key.module)}.#{Atom.to_string(run.key.function)}\
       #{print_dependencies(run)}\
    """)

    :ok
  end

  @spec pretty_run(atom()) :: :ok
  def pretty_run(module) do
    module
    |> ExExample.execution_order()
    |> Enum.map(&attempt_example(&1, []))
    |> Enum.each(&print_run/1)

    :ok
  end

  @doc """
  I return the last known result of an example invocation.
  If the example has not been run yet I return an error.
  """
  @spec last_result(ExExample.dependency()) :: :success | :skipped | :failed | :no_cache
  def last_result({{module, func}, _arity}) do
    deps_hash = dependency_hash({module, func})

    key = %Cache.Key{module: module, function: func, arguments: [], deps_hash: deps_hash}

    case Cache.get_result(key) do
      {:ok, result} ->
        result.success

      {:error, :no_result} ->
        :no_cache
    end
  end

  @doc """
  Given an example, I return a map of all its dependencies
  that failed, succeeded, were skipped, or have not run yet.
  """
  @spec dependency_results({atom(), atom()}) :: %{
          success: [ExExample.dependency()],
          skipped: [ExExample.dependency()],
          failed: [ExExample.dependency()],
          no_cache: [ExExample.dependency()]
        }
  def dependency_results({module, func}) do
    results =
      {module, func}
      |> ExExample.example_dependencies()
      |> Enum.group_by(&last_result/1)

    Map.merge(%{success: [], skipped: [], failed: [], no_cache: []}, results)
  end

  @doc """
  Given an example, I return a hash of all its dependencies.
  This hash can be used to determine of an example was run with
  an older version of a dependency.
  """
  @spec dependency_hash({atom(), atom()}) :: non_neg_integer()
  def dependency_hash({module, func}) do
    {module, func}
    |> ExExample.all_dependencies()
    |> Enum.map(fn {{module, _func}, _arity} ->
      {module, module.__info__(:attributes)[:vsn]}
    end)
    |> Enum.uniq()
    |> :erlang.phash2()
  end

  @doc """
  I run all the examples in the given module.
  I use the cache for each invocation.
  """
  @spec run_all_examples(atom()) :: [Run.t()]
  def run_all_examples(module) do
    module
    |> ExExample.execution_order()
    |> Enum.map(&attempt_example(&1, []))
  end

  @doc """
  I attempt to run an example.

  I return a struct that holds the result, the key, and a list of all
  the dependencies and their previous result.
  """
  @spec attempt_example({atom(), atom()}, [any()]) :: Run.t()
  def attempt_example({module, func}, arguments) do
    deps_hash = dependency_hash({module, func})
    key = %Cache.Key{module: module, function: func, arguments: arguments, deps_hash: deps_hash}

    case dependency_results({module, func}) do
      # no failures, only no cache or success
      %{failed: [], skipped: [], no_cache: no_cache, success: success} ->
        result = run_example_with_cache({module, func}, arguments)
        %Run{key: key, result: result, no_cache: no_cache, success: success}

      # failures and/or skipped
      %{failed: failed, skipped: skipped, no_cache: no_cache, success: success} ->
        result = %Cache.Result{key: key, success: :skipped, result: nil, cached: false}
        Cache.put_result(result, key)

        %Run{
          key: key,
          result: result,
          no_cache: no_cache,
          success: success,
          failed: failed,
          skipped: skipped
        }
    end
  end

  @doc """
  I run an example with the cached results.
  If there is cached result, I return that.
  If there is no result in the cache I run the example.
  """
  @spec run_example_with_cache({atom(), atom()}, [any()]) :: Cache.Result.t()
  def run_example_with_cache({module, func}, arguments) do
    deps_hash = dependency_hash({module, func})
    key = %Cache.Key{module: module, function: func, arguments: arguments, deps_hash: deps_hash}

    case Cache.get_result(key) do
      {:ok, result} ->
        if module.rerun?(result.result) do
          run_example({module, func}, arguments)
        else
          %{result | result: module.copy(result.result)}
        end

      {:error, :no_result} ->
        run_example({module, func}, arguments)
    end
  end

  @doc """
  I run an example directly. I do not consult the cache for a previous result.
  I return a result of this execution and put it in the cache.
  """
  @spec run_example({atom(), atom()}, [any()]) :: Cache.Result.t()
  def run_example({module, func}, arguments) do
    deps_hash = dependency_hash({module, func})
    key = %Cache.Key{module: module, function: func, arguments: arguments, deps_hash: deps_hash}

    result =
      try do
        {module, func} = ExExample.hidden_name({module, func})
        result = apply(module, func, arguments)
        %Cache.Result{key: key, success: :success, result: result}
      rescue
        e ->
          %Cache.Result{key: key, success: :failed, result: e}
      end

    # store the result in the cache
    Cache.put_result(result, key)

    %{result | cached: false}
  end

  @doc """
  Given an example, I return a hash of all its dependencies.
  This hash can be used to determine of an example was run with
  an older version of a dependency.
  """
  @spec deps_hash(list(ExExample.dependency())) :: non_neg_integer()
  def deps_hash(dependencies) do
    dependencies
    |> Enum.map(fn {{module, _func}, _arity} ->
      module.__info__(:attributes)[:vsn]
    end)
    |> :erlang.phash2()
  end
end
