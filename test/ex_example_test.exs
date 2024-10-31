defmodule ExExampleTest do
  use ExUnit.Case
  doctest ExExample

  test "greets the world" do
    assert ExExample.hello() == :world
  end
end
