defmodule ExExample.Run do
  @moduledoc """
  I am the result of running an example.

  I contain meta-data about this particular invocation such as
  whether the example was found in cache, the state of its dependencies,
  and the key.
  """
  alias ExExample.Cache.Key
  alias ExExample.Cache.Result

  use TypedStruct

  typedstruct do
    field(:cached, boolean(), default: true)
    field(:key, Key.t())
    field(:result, Result.t())
    field(:skipped, [ExExample.dependency()], default: [])
    field(:failed, [ExExample.dependency()], default: [])
    field(:no_cache, [ExExample.dependency()], default: [])
    field(:success, [ExExample.dependency()], default: [])
  end
end
