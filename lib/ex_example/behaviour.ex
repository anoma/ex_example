defmodule ExExample.Behaviour do
  @moduledoc """
  I help determine when Examples ought to be run again or be copied


  I do this by defining out a behaviour that is to be used with the
  use macro for ExExample
  """

  @callback rerun?(ExExample.CacheResult.t()) :: boolean()
  @callback copy(ExExample.CacheResult.t()) :: any()
end
