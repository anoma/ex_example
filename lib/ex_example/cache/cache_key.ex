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
    field(:deps_hash, integer())
    field(:module, atom())
    field(:name, String.t() | atom())
    field(:arity, non_neg_integer(), default: 0)
    field(:arguments, list(any()), default: [])
  end
end
