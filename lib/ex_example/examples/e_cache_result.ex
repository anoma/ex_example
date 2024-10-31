defmodule ExExample.Examples.ECacheResult do
  alias ExExample.CacheResult

  def trivial_definition() do
    5
  end

  def trivial_cached_result do
    %CacheResult{
      source: [do: 5],
      pure: true,
      result: 5,
      source_name: {__MODULE__, :trivial_definition, 0}
    }
  end
end
