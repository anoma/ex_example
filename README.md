# ExExample

`ExExample` aims to provide an example-driven test framework for Elixir applications.

As opposed to regular unit tests, examples are supposed to be executed from within the REPL.

Examples serve both as a unit test, but also as a tool to discover, learn, and interact with a live
system such as Elixir applications.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_example` to your list of dependencies in `mix.exs`:

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
  defexample read_data() do
    1..1000 |> Enum.shuffle() |> Enum.take(10)
  end
end
```

In a running REPL with your application loaded, you can execute this example using `MyExamples.read_data()`.
The example will be executed once, and the cached result will be returned the next time around.

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
  use ExExample.Test, for: MyExamples
end
```