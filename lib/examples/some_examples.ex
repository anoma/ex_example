defmodule ExExample.Examples.SomeExamples do
  use ExExample

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
end
