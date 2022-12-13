defmodule Haytni.Mailer.DeliveryStrategy do
  @moduledoc ~S"""
  TODO (doc)
  """

  @doc ~S"""
  TODO (doc)
  """
  @type email_sent :: :ok | {:error, any}
  @callback deliver(email :: Haytni.Mail.t, mailer :: module, options :: Keyword.t) :: email_sent

  defmacro __using__(_options) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end
end
