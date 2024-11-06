defmodule ExExample.Test do
  @moduledoc """
  I define a macro that runs examples as part of the unit tests.

  To use me, you need to `use ExExample.Test, for: Module` in your test module, where `Module` is
  the module that contains the examples.
  """
  use ExUnit.Case

  defmacro __using__(opts) do
    quote do
      unquote(opts)[:for].run_examples()
    end
  end
end
