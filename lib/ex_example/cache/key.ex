defmodule ExExample.Cache.Key do
  @moduledoc """
  I represent the key for an example invocation.

  I identify an invocation by means of its module, name, arity, and list of arguments.
  """
  use TypedStruct

  typedstruct enforce: true do
    @typedoc """
    I represent the key for an example invocation.
    """
    field(:module, atom())
    field(:function, atom())
    field(:arguments, [term()], default: [])
    field(:deps_hash, any(), default: nil)
  end
end
