defmodule Examples.Stack do
  # all exmaples must return a Stack
  @moduledoc """
  I contain examples that test the `Stack` implementation.
  """
  use ExExample

  import ExUnit.Assertions

  example new_stack do
    {:ok, stack} = Stack.create([])
    assert stack == %Stack{elements: []}
    stack
  end

  example empty_stack_should_be_empty do
    stack = new_stack()
    assert Stack.empty?(stack)
    stack
  end

  example push_stack do
    stack = new_stack()
    {:ok, stack} = Stack.push(stack, 1)
    assert stack == %Stack{elements: [1]}
    stack
  end

  example pop_stack do
    stack = push_stack()
    {:ok, stack, 1} = Stack.pop(stack)
    stack
  end

  @spec copy(any()) :: Stack.t()
  def copy(stack) do
    %Stack{elements: stack.elements}
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
