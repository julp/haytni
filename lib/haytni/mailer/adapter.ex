defmodule Haytni.Mailer.Adapter do
  @moduledoc ~S"""
  For the needs of mail abstraction, sending an email is split in two operations:

  1. casting, to convert the `%Haytni.Mail{}` struct into another one that your real
     sender (Bamboo or Swoosh for example) can work on.
  2. sending, apart

  Sending is a separate operation since, especially in testing, is not always required: if
  you just want to test the content of the mail, you can spare this second step.
  """

  @doc ~S"""
  Convert a `%Haytni.Mail{}` struct into a one that the email library you use can work on
  (eg: a `%Bamboo.Email{}` for Bamboo).
  """
  @callback cast(email :: Haytni.Mail.t, mailer :: module, options :: Keyword.t) :: struct

  @doc ~S"""
  Send the email (in a synchronous fashion)
  """
  @callback send(email :: struct, mailer :: module, options :: Keyword.t) :: :ok | {:error, any}

  defmacro __using__(_options) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end
end
