defmodule ExExample.Tests do
  @moduledoc """
  I generate a test for the given module that runs all of its examples.
  """
  defmacro __using__(for: module) do
    alias ExExample.Cache

    module_to_test = Macro.expand(module, __CALLER__)
    examples = ExExample.execution_order(module_to_test)

    for {mod, func} <- examples do
      quote do
        test "#{inspect(unquote(mod))}.#{Atom.to_string(unquote(func))}" do
          case ExExample.Executor.attempt_example({unquote(mod), unquote(func)}, []) do
            %{result: %Cache.Result{success: :failed} = result} ->
              raise result.result

            _ ->
              :ok
          end
        end
      end
    end
  end
end
