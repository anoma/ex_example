defmodule Stack do
  @type t :: %{
          elements: list(any())
        }
  defstruct elements: []

  @spec create() :: {:ok, Stack.t()}
  def create() do
    {:ok, %Stack{}}
  end

  @spec empty?(Stack.t()) :: boolean
  def empty?(%Stack{elements: []}), do: true
  def empty?(%Stack{elements: _}), do: false

  @spec push(Stack.t(), any()) :: {:ok, Stack.t()}
  def push(%Stack{elements: xs}, x) do
    {:ok, %Stack{elements: [x | xs]}}
  end

  @spec pop(Stack.t()) :: {:ok, Stack.t(), any()} | {:error, :empty}
  def pop(%Stack{elements: []}) do
    {:error, :empty}
  end

  def pop(%Stack{elements: [x | xs]}) do
    {:ok, %Stack{elements: xs}, x}
  end

  @spec peek(Stack.t()) :: {:ok, Stack.t(), any()} | {:error, :empty}
  def peek(%Stack{elements: []}) do
    {:error, :empty}
  end

  def peek(%Stack{elements: [x | xs]}) do
    {:ok, %Stack{elements: [x | xs]}, x}
  end
end
