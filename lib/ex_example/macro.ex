defmodule ExExample.Macro do
  @moduledoc """
  I define the macros used to define examples.
  """
  # alias ExExample.Cache
  # alias ExExample.CacheResult
  alias ExExample.Analyze

  defmacro defexample(name, do: body) do
    # destruct function name
    {func_name, pos, args} = name

    # arity of the example function
    arity = Enum.count(args)

    # information about the example to lookup in the cache
    caller_module = __CALLER__.module

    # create the uncached function name
    no_cache_func_name = String.to_atom("#{func_name}_no_cache")
    no_cache_name = {no_cache_func_name, pos, args}

    quote do
      # i am the uncached version of the example
      def unquote(no_cache_name) do
        unquote(body)
      end

      # register the cached function as an example
      @examples unquote(no_cache_func_name)
      # i define the example logic but check if there is a result in cache
      # before executing
      def unquote(name) do
        key = %ExExample.Cache.Key{
          deps_hash: Analyze.dependencies_hash(unquote(caller_module)),
          module: unquote(caller_module),
          name: unquote(func_name),
          arity: unquote(arity),
          arguments: unquote(args)
        }

        ExExample.Execute.execute_example(key, unquote(args))
      end
    end
  end
end
