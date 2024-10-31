defmodule ExExample.Supervisor do
  @moduledoc """
  I am the ExUnit Supervisor for Caching.
  """

  use Supervisor

  @type startup_options :: {:name, atom()}

  @spec start_link(list(startup_options())) :: GenServer.on_start()
  def start_link(args \\ []) do
    {:ok, keys} =
      args
      |> Keyword.validate(name: __MODULE__)

    Supervisor.start_link(__MODULE__, keys, name: keys[:name])
  end

  @impl true
  def init(_args) do
    children = [{Cachex, [:ex_examples]}]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
