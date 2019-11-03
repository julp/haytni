defmodule HaytniTest.Mailer do
  use Bamboo.Mailer, otp_app: :haytni

  def from, do: {"mydomain.com", "noreply.mydomain.com"}
end
