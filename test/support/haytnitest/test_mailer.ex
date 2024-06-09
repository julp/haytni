defmodule HaytniTest.TestMailer do
  use Haytni.Mailer, [
    otp_app: :haytni,
    adapter: Haytni.Mailer.TestAdapter,
  ]

  @impl Haytni.Mailer
  def from, do: {"mydomain.com", "noreply@mydomain.com"}
end
