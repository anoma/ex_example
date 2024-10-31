defmodule ExExample do
  @moduledoc """
  I am the ExExample Application Module

  I startup the ExExample system as an OTP application. Moreover Ι
  provide all the API necessary for the user of the system. I contain
  all public functionality

  ### Public API
  """

  use Application

  def start(_type, args \\ []) do
    ExExample.Supervisor.start_link(args)
  end
end
