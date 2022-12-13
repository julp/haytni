defmodule Haytni.Mailer do
  @moduledoc ~S"""
  TODO (doc)
  """

  @doc ~S"""
  Sets the *from* header of the emails you send.

  It should return a string (`"noreply@mydomain.com"`) or a tuple of the form: `{name, email address}` (eg: `{"mydomain.com", "noreply@mydomain.com"}`)
  """
  @callback from() :: String.t | {String.t, String.t}

  defmacro __using__(options) do
    otp_app = Keyword.fetch!(options, :otp_app)

    strategy = Keyword.get(options, :strategy, Haytni.Mailer.ImmediateDeliveryStrategy)
    # strategy.deliver(mailer, email, options) # mailer = __MODULE__

    delivering =
      options
      |> Keyword.get(:adapter)
      |> case do
        nil ->
          quote do
            @behaviour Haytni.Mailer.Adapter
          end
        adapter ->
          quote do
            use unquote(adapter), otp_app: unquote(otp_app)
          end
      end

    quote do
      @behaviour unquote(__MODULE__)

      unquote(delivering)
    end
  end
end
