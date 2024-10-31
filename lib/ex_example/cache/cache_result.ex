defmodule ExExample.Cache.Result do
  @moduledoc """
  I represent the cached result of a ran Example
  """

  alias ExExample.Cache.Key

  use TypedStruct

  typedstruct enforce: false do
    @typedoc """
    I represent the result of a completed Example Computation
    """
    field(:key, Key.t())
    field(:result, term())
  end
end
