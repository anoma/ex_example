# ExExample

`ExExample` aims to provide an example-driven test framework for Elixir applications.

As opposed to regular unit tests, examples are supposed to be executed from within the REPL.

Examples serve both as a unit test, but also as a tool to discover, learn, and interact with a live
system such as Elixir applications.

## Installation

Add `ex_example` as a dependency in your `mix.exs` file.
(Don't limit it to `:dev` or `:test` environments.)

```elixir
def deps do
  [
    {:ex_example, "~> 0.1.0"}
  ]
end
```

## Your First Example

To get started, create a new module in the `lib/` folder of your Elixir application and add an example.

```elixir
defmodule MyExamples do
  use ExExample

  example read_data do
    1..1000 |> Enum.shuffle() |> Enum.take(10)
  end

  @spec copy(any()) :: Stack.t()
  def copy(stack) do
    %Stack{elements: stack.elements}
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
```

In a running REPL with your application loaded, you can execute this example using `MyExamples.read_data()`.
The example will be executed once, and the cached result will be returned the next time around.

The optional callbacks `copy/1` and `rerun?/1` are used to change the caching behavior.
These functions are called whenever an example within the module they're defined in are executed.

The `copy/1` function takes in the previous result value if there was one, and allows you to define custom logic on how to copy a value.
This is especially useful if you return values that are mutable (e.g., process ids).
For example, if you want to create a copy of a supervision tree, you define the logic to clone that supervision tree in the `copy/1` function.
This is useful if you have examples that change that value, while other examples do not expect their inputs to be changed.

The `rerun?/1` function takes in the result of an already run example, and determines based on its output if it should be recomputed anyway.
This is useful to circumvent the caching mechanism in case you do not want cached values in examples.

## Caching

In a REPL session it's not uncommon to recompile your code (e.g., using `recompile()`). This changes
the semantics of your examples.

To avoid working with stale outputs, `ExExample` only returns the cached version of your example
if the code it depends on, or the example itself, have not been changed.

When the code changes, the example is executed again.

## Tests

The examples are created to work with the code base, but they can also serve as a unit test.

To let ExUnit use the examples in your codebase as tests, add a test file in the `test/` folder, and
import the `ExExample.Test` module.

To run the examples from above, add a file `ny_examples_test.exs` to your `test/` folder and include the following.

```elixir
defmodule MyExamplesTest do
  use ExUnit.Case
  use ExExample.ExUnit, for: MyExamples
end
```