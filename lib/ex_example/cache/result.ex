defmodule ExExample.Cache.Result do
  @moduledoc """
  I represent the result of an example execution.

  I contain the key for the example I am the result of, the status of the execution, and the result of the execution.
  """
  use TypedStruct

  alias ExExample.Cache.Key

  typedstruct enforce: false do
    @typedoc """
    I represent the result of a completed Example Computation
    """
    field(:key, Key.t())
    field(:success, :failed | :success | :skipped)
    field(:result, term())
    field(:cached, boolean(), default: true)
  end
end
