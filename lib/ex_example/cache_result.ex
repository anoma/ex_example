defmodule ExExample.CacheResult do
  @moduledoc """
  I represent the cached result of a ran Example
  """

  use TypedStruct

  typedstruct enforce: true do
    @typedoc """
    I represent the result of a completed Example Computation
    """

    field(:source, Macro.input())
    field(:source_name, atom())
    field(:result, term())
    field(:pure, boolean())
  end
end