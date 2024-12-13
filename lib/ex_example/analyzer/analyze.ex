defmodule ExExample.Analyze do
  @moduledoc """
  I contain functionality to analyze ASTs.

  I have functionality to extract modules on which an AST depends,
  function calls it makes, and definitions from a module AST.
  """
  require Logger

  defmodule State do
    @moduledoc """
    I implement the state for analyzing an AST.
    """
    defstruct called_functions: [], env: nil, functions: []

    @spec put_call(map(), {atom(), atom()}, non_neg_integer()) :: map()
    def put_call(state, mod, arg) do
      %{state | called_functions: [{mod, arg} | state.called_functions]}
    end

    @spec put_def(map(), atom(), non_neg_integer()) :: map()
    def put_def(state, func, arity) do
      %{state | functions: [{func, arity} | state.functions]}
    end
  end

  # ----------------------------------------------------------------------------
  # Exctract function calls from ast

  @spec extract_function_calls(tuple(), Macro.Env.t()) :: [{{atom(), atom()}, non_neg_integer()}]
  def extract_function_calls(ast, env) do
    state = %State{env: env}
    # IO.inspect(env)
    {_, state} = Macro.prewalk(ast, state, &extract_function_calls_logged/2)
    state.called_functions
  end

  defp extract_function_calls_logged(ast, state) do
    # IO.puts("------------------------------------------- ")
    # IO.inspect(ast)

    extract_function_call(ast, state)
  end

  # qualified function call
  # e.g., Foo.bar()

  defp extract_function_call(
         {{:., _, [{:__aliases__, _, aliases}, func_name]}, _, args} = ast,
         state
       ) do
    case Macro.Env.expand_alias(state.env, [], aliases) do
      :error ->
        arg_count = Enum.count(args)
        module = Module.concat(aliases)
        state = State.put_call(state, {module, func_name}, arg_count)
        {ast, state}

      {:alias, resolved} ->
        arg_count = Enum.count(args)
        state = State.put_call(state, {resolved, func_name}, arg_count)
        {ast, state}
    end
  end

  defp extract_function_call({{:., _, _args}, _, _} = ast, state) do
    {ast, state}
  end

  # variable in binding
  # e.g. `x` in `x = 1`
  defp extract_function_call({_func, _, nil} = ast, state) do
    {ast, state}
  end

  @special_forms Kernel.SpecialForms.__info__(:macros)
  defp extract_function_call({func, _, args} = ast, state) do
    arg_count = Enum.count(args)

    state =
      case Macro.Env.lookup_import(state.env, {func, arg_count}) do
        # imported call
        [{:function, module}] ->
          State.put_call(state, {module, func}, arg_count)

        [{:macro, _module}] ->
          state

        # local def
        [] ->
          if {func, arg_count} in @special_forms or func in [:__block__, :&, :__aliases__] do
            state
          else
            State.put_call(state, {state.env.module, func}, arg_count)
          end
      end

    {ast, state}
  end

  defp extract_function_call(ast, state) do
    {ast, state}
  end

  # ----------------------------------------------------------------------------
  # Exctract function definitions from module

  @doc """
  Given the path of a source file, I extract the definitions of the functions.
  """
  @spec extract_defs(String.t(), Macro.Env.t()) :: [{atom(), non_neg_integer()}]
  def extract_defs(file, env) do
    source = File.read!(file)
    {:ok, ast} = Code.string_to_quoted(source)
    extract_defs_from_source(ast, env)
  end

  defp extract_defs_from_source(ast, env) do
    # create the initial state
    state = %State{env: env}

    # walk the ast and extract the function definitions
    {_, state} = Macro.prewalk(ast, state, &extract_def_logged/2)

    state.functions
  end

  defp extract_def_logged(ast, state) do
    # IO.puts("------------------------------------------- ")
    # IO.inspect(ast)

    extract_def(ast, state)
  end

  defp extract_def({:example, _, [{fun, _, args}, _body]} = ast, state) do
    state =
      args
      |> count_args()
      |> Enum.reduce(state, fn i, state ->
        State.put_def(state, fun, i)
      end)

    {ast, state}
  end

  defp extract_def(ast, state) do
    {ast, state}
  end

  # @doc """
  # I count the arguments in an argument list.
  # I return the number of required arguments followed by the number of optional arguments.
  # """
  @spec count_args([any()]) :: any()
  defp count_args(args) do
    {req, opt} =
      args
      |> Enum.reduce({0, 0}, fn
        {:\\, _, [{_arg, _, _}, _]}, {req, opt} ->
          {req, opt + 1}

        _, {req, opt} ->
          {req + 1, opt}
      end)

    req..(req + opt)
  end
end
