defmodule Haytni.Mailer.ImmediateDeliveryStrategy do
  @moduledoc ~S"""
  This is the strategy to send email immediately (synchronously - the user has to wait after the email was fully sent).
  """
  use Haytni.Mailer.DeliveryStrategy

  @impl Haytni.Mailer.DeliveryStrategy
  def deliver(email = %Haytni.Mail{}, mailer, options) do
    email
    |> mailer.cast(mailer, options)
    |> mailer.send(mailer, options)
  end
end
