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

  @doc """
  I am the use macro for ExExample.

  I import the ExExample.Behaviour module, expose the macros, and define the `copy/1` and `rerun?/1` callbacks.
  """
  defmacro __using__(_options) do
    quote do
      import unquote(ExExample.Macro)
      # module attribute that holds all the examples
      Module.register_attribute(__MODULE__, :examples, accumulate: true)

      # import the behavior for the callbacks
      @behaviour ExExample.Behaviour

      # default implementation of the callbacks
      def copy(result) do
        result
      end

      def rerun?(_result) do
        false
      end

      # mark the callbacks are overridable.
      defoverridable copy: 1
      defoverridable rerun?: 1

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def run_examples() do
        Enum.each(@examples, fn example ->
          apply(__MODULE__, example, [])
        end)
      end
    end
  end
end
