defmodule HaytniTest.SwooshMailer do
  use Haytni.Mailer, [
    otp_app: :haytni,
    adapter: Haytni.Mailer.SwooshAdapter,
  ]

  @impl Haytni.Mailer
  def from, do: {"mydomain.com", "noreply@mydomain.com"}
end
