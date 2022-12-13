defmodule HaytniTest.BambooMailer do
  use Haytni.Mailer, [
    otp_app: :haytni,
    adapter: Haytni.Mailer.BambooAdapter,
  ]

  @impl Haytni.Mailer
  def from, do: {"mydomain.com", "noreply@mydomain.com"}
end
