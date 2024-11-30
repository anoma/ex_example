defmodule ExExample.Examples.SomeExamples do
  use ExExample

  import ExUnit.Assertions

  @doc """
  I create an empty stack and return it.
  """
  defexample create_stack() do
    {:ok, stack} = Stack.create()
    stack
  end

  @depends [:create_stack]
  defexample push(stack) do
    {:ok, stack} = Stack.push(stack, 1)
    stack
  end

  @depends [:push]
  defexample pop(stack) do
    {:ok, stack, _element} = Stack.pop(stack)
    assert stack.elements |> Enum.count() == 0
    stack
  end

  @depends [:push]
  defexample peek(stack) do
    {:ok, stack, _element} = Stack.peek(stack)
    stack
  end

  @depends [:push]
  defexample peek_empty(stack) do
    {:ok, stack, _element} = Stack.peek(stack)
    stack
  end

  @depends [:create_stack]
  defexample empty_1?(stack) do
    true = Stack.empty?(stack)
    stack
  end

  @depends [:push]
  defexample empty_2?(stack) do
    false = Stack.empty?(stack)
    stack
  end

  @depends [:pop, :push]
  defexample compare_stacks(stack1, stack2) do
    assert stack1.elements != stack2.elements
    nil
  end
end
