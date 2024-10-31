defmodule ExExample.Analyze do
  @moduledoc """
  I contain functions that help analyzing modules and their dependencies.

  I have functionality to extract a list of modules that are being called by a module, as well
  as a function to calculate a hash for a module and its dependencies.
  """

  @doc """
  I return a hash for the given module and its dependencies.

  When any of these dependencies are recompiled, this hash will change.
  """
  @spec dependencies_hash(atom() | String.t() | tuple()) :: integer()
  def dependencies_hash(module) do
    module
    |> dependencies()
    |> Enum.map(& &1.module_info())
    |> :erlang.phash2()
  end

  @doc """
  I analyze the module and return a list of all the modules it calls.
  I accept a module name, a piece of code as string, or an AST.
  """
  @spec dependencies(atom() | String.t() | tuple()) :: MapSet.t(atom())
  def dependencies(module) when is_atom(module) do
    case get_in(module.module_info(), [:compile, :source]) do
      nil ->
        []

      source ->
        to_string(source)
        |> File.read!()
        |> dependencies()
    end
  end

  def dependencies(module) when is_binary(module) do
    module
    |> Code.string_to_quoted()
    |> dependencies()
  end

  def dependencies(module) when is_tuple(module) do
    deps_for_module(module)
  end

  @doc """
  I extract all the modules that the given AST calls.

  Aliases that are not used are ignored.
  """
  @spec deps_for_module(Macro.t()) :: MapSet.t(atom())
  def deps_for_module(ast) do
    # extract all the alias as expressions
    {_, deps} =
      Macro.postwalk(ast, %{}, fn
        # a top-level alias. E.g., `alias Foo.Bar, as: Bloop`
        # {:alias, [line: 3], [{:__aliases__, [line: 3], [:Bloop]}, [as: {:__aliases__, [line: 3], [:Bar]}]]}
        ast = {:alias, _, [{:__aliases__, _, aliases}, [as: {:__aliases__, _, [as_alias]}]]}, acc ->
          # canonicalize the alias atoms
          aliases = Enum.map(aliases, &Module.concat([&1]))
          as_alias = Module.concat([as_alias])

          # check if the root has been aliased, replace if so
          [root | rest] = aliases
          root = Map.get(acc, root, root)
          aliases = [root | rest]

          # if the first atom is an alias, resolve it
          module = Module.concat(aliases)
          {ast, Map.put(acc, as_alias, module)}

        # alias erlang module. E.g., `alias :code, as: Code`
        ast = {:alias, _, [module, [as: {:__aliases__, _, [as_alias]}]]}, acc when is_atom(module) ->
          as_alias = Module.concat([as_alias])
          {ast, Map.put(acc, as_alias, module)}

        # a top-level alias. E.g., `alias Foo.Bar`
        # {:alias, [line: 2], [{:__aliases__, [line: 2], [:X, :Y]}]}
        ast = {:alias, _, [{:__aliases__, _, aliases}]}, acc ->
          # canonicalize the alias atoms
          aliases = Enum.map(aliases, &Module.concat([&1]))

          # check if the root has been aliased, replace if so
          [root | rest] = aliases
          root = Map.get(acc, root, root)
          aliases = [root | rest]

          # store the alias chain
          module = Module.concat(aliases)
          aliased = List.last(aliases)
          {ast, Map.put(acc, aliased, module)}

        # top-level group alias. E.g., `alias Foo.{Bar, Baz}`
        # {:alias, [line: 2], [{:__aliases__, [line: 2], [:X, :Y]}]}
        ast = {{:., _, [{:__aliases__, _, aliases}, :{}]}, _, sub_alias_list}, acc ->
          # canonicalize the alias atoms
          aliases =
            Enum.map(aliases, &Module.concat([&1]))

          # check if the root is an alias
          # check if the root has been aliased, replace if so
          [root | rest] = aliases
          root = Map.get(acc, root, root)
          aliases = [root | rest]

          # resolve the subaliases
          acc =
            for {:__aliases__, _, sub_aliases} <- sub_alias_list, into: acc do
              sub_aliases = Enum.map(sub_aliases, &Module.concat([&1]))
              aliased_as = List.last(sub_aliases)
              {aliased_as, Module.concat(aliases ++ sub_aliases)}
            end

          {ast, acc}

        # function call to module. E.g., `Foo.func()`
        # {:alias, [line: 2], [{:__aliases__, [line: 2], [:X, :Y]}]}
        ast = {{:., _, [{:__aliases__, _, aliases}, _func]}, _, _args}, acc ->
          # canonicalize the alias atoms
          aliases = Enum.map(aliases, &Module.concat([&1]))

          # check if the root is an alias
          # check if the root has been aliased, replace if so
          [root | rest] = aliases
          root = Map.get(acc, root, root)
          aliases = [root | rest]

          # canonicalize the alias atoms
          module = Module.concat(aliases)
          {ast, Map.update(acc, :calls, MapSet.new([module]), &MapSet.put(&1, module))}

        # the module itself is included in the dependencies
        ast = {:defmodule, _, [{:__aliases__, _, module_name}, _]}, acc ->
          module_name = Module.concat(module_name)
          acc = Map.update(acc, :calls, MapSet.new([module_name]), &MapSet.put(&1, module_name))
          {ast, acc}

        ast, acc ->
          {ast, acc}
      end)

    Map.get(deps, :calls, [])
  end
end
