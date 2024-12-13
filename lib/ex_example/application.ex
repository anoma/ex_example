defmodule ExExample.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [{Cachex, [ExExample.Cache]}]

    opts = [strategy: :one_for_one, name: ExExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
