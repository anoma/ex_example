defmodule ExExample.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    logger_level = Application.get_env(:ex_example, :logger_level, :error)
    Logger.put_application_level(:ex_example, logger_level)

    children = [{Cachex, [ExExample.Cache]}]

    opts = [strategy: :one_for_one, name: ExExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
