defmodule Stack do
  @moduledoc """
  I am an example implementation of a Stack. I am used to show example.. examples.
  """
  use TypedStruct

  typedstruct enforce: true do
    @typedoc """
    I represent the key for an example invocation.
    """
    field(:elements, [any()], default: [])
  end

  @spec create() :: {:ok, t()}
  def create do
    {:ok, %Stack{}}
  end

  # yesyesyes
  @spec empty?(t()) :: boolean
  def empty?(%Stack{elements: []}), do: true
  def empty?(%Stack{elements: _}), do: false

  @spec push(t(), any()) :: {:ok, t()}
  def push(%Stack{elements: xs}, x) do
    {:ok, %Stack{elements: [x | xs]}}
  end

  @spec pop(t()) :: {:ok, t(), any()} | {:error, :empty}
  def pop(%Stack{elements: []}) do
    {:error, :empty}
  end

  def pop(%Stack{elements: [x | xs]}) do
    {:ok, %Stack{elements: xs}, x}
  end

  @spec peek(t()) :: {:ok, t(), any()} | {:error, :empty}
  def peek(%Stack{elements: []}) do
    {:error, :empty}
  end

  def peek(%Stack{elements: [x | xs]}) do
    {:ok, %Stack{elements: [x | xs]}, x}
  end
end
