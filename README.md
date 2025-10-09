# ExExample

`ExExample` is an examples framework for Elixir projects.

As opposed to regular unit tests, examples are supposed to be executed from
within the REPL. Examples return useful values, and can build upon one 
another; they subsume all of "REPL helpers", "unit tests", and "test fixtures".

Examples serve both as a unit test, but also as a tool to discover, learn, and
interact with a live system such as an Elixir application.

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

To get started, create a new module in the `lib/` folder of your Elixir
application and add an example.

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

In a running REPL with your application loaded, you can execute this example
using `MyExamples.read_data()`.
The example will be executed once, and the cached result will be returned the
next time around.

The optional callbacks `copy/1` and `rerun?/1` are used to change the caching
behavior.
These functions are called whenever an example within the module they're defined
in are executed.

The `copy/1` function takes in the previous result value if there was one, and
allows you to define custom logic on how to copy a value.
This is especially useful if you return values that are mutable (e.g., process
ids).
For example, if you want to create a copy of a supervision tree, you define the
logic to clone that supervision tree in the `copy/1` function.
This is useful if you have examples building on it that change that value, 
because other examples do not expect their inputs to have been modified.

The `rerun?/1` function takes in the result of an already run example, and
determines based on its output if it should be recomputed anyway.
This is useful to circumvent the caching mechanism in case you do not want
cached values in examples.

## Using Examples

From the REPL, just use them as ordinary functions:

```iex
iex> Examples.Stack.new_stack
%Stack{elements: []}
```

For a more detailed view of all the examples in a module, use
`ExExample.Executor.pretty_run/1`.

```iex
iex> ExExample.Executor.pretty_run(Examples.Stack)
good (cached) Examples.Stack.new_stack   
good (cached) Examples.Stack.push_value   
+   good Examples.Stack.new_stack
good (cached) Examples.Stack.push_stack   
+   good Examples.Stack.new_stack
good (cached) Examples.Stack.pop_stack   
+   good Examples.Stack.push_stack
good (cached) Examples.Stack.empty_stack_should_be_empty   
+   good Examples.Stack.new_stack
:ok
```

Examples may also be run as tests from `mix test` with the `ExUnit` 
integration; see **ExUnit Integration** below.

## Writing Examples

We often use the `Examples` top-level module namespace for example modules, 
but you can name them anything you'd like.

An example is more or less the same as a `def`. It exports a function with 
the given name from the example module; i.e., the above `MyExamples` module 
exports `MyExamples.read_data/0`.

An example may have arguments, too. To support their use as tests, any 
arguments must provide default values with `\\`. That is,
`example push_value(v \\ "example value")`, not `example push_value(v)`.

Examples can and should build on one another (don't worry about expensively 
rerunning them; see **Caching** below), because they return useful values. 
The following shows how this might be done:

```elixir
defmodule MyExamples do
  example new_stack do
    []
  end
  
  example push_one_to_empty do
    stack = new_stack()
    [1 | stack]
  end
  
  example push_value_to_empty(v \\ "example value") do
    stack = new_stack()
    [v | stack]
  end
  
  example push_one_two_to_empty do
    stack = push_one()
    [2 | stack]
  end
end
```

You may wish to make assertions about invariants in your examples. 
`ExExample` doesn't provide assertions; it wouldn't add anything that
`ExUnit.Assertions` doesn't already provide. Feel free to import
`ExUnit.Assertions` and assert things; this provides helpful error messages 
both in the REPL and in test runs.

## Copying

As discussed above, it's assumed by default that values returned from 
examples are ordinary terms - that is, immutable. Sometimes this isn't the 
case; it could be that the value is or contains things like PIDs (if you're 
returning a struct representing a whole supervision tree), references (maybe 
ETS tables), or otherwise has different semantics.

But when building examples on one another, the assumption is that the result 
of e.g. "new_subsystem" is a fresh instance of the subsystem, not one that 
has had its state modified by later examples.

If this is the case, you can define the `copy/1` callback. The standard 
catchall behavior for ordinary terms is `def copy(item), do: item`, but you 
can specify your own for anything an example might return.

The `rerun?/1` callback serves a related function; you can have it return 
`true` for any value that should always be recomputed, even if it's cached.

## Caching

In a REPL session it's not uncommon to recompile your code (e.g., using
`recompile()`). This changes the semantics of your examples.

To avoid working with stale outputs, `ExExample` only returns the cached version
of your example if the code it depends on, or the example itself, have not been
changed.

When the code changes, the example is executed again.

If an example has arguments, the cache key includes the argument values as well.

If you wish to purge the entire cache, use `ExExample.Cache.clear/0` (and
then please report the cache invalidation bug to us!).

## ExUnit Integration

`ExExample` has a direct integration with `ExUnit`, which runs every example
in a module in order as `ExUnit.Case` tests. Use it by writing your
`test/module_test.exs` file as follows:

```elixir
defmodule MyExamplesTest do
  use ExExample.ExUnit, for: MyExamples
end
```

This expands to a `test` for each example in `MyExamples`. You can add e.g.
doctests for relevant modules as well below, if you like.