defmodule Hayni.Mail.SwooshAdapterTest do
  use HaytniWeb.EmailCase, [
    email: :swoosh,
  ]

  describe "Haytni.Mailer.SwooshAdapter" do
    test "cast/3 returns a %Swoosh.Email{}" do
      email = HaytniWeb.EmailCase.dummy_email(@stack)
      casted_email = @adapter.cast(email, @mailer, [])

      assert casted_email.__struct__ == Swoosh.Email
      assert casted_email.to == [{"", email.to}]
      assert casted_email.subject == email.subject
      assert casted_email.html_body == email.html_body
      assert casted_email.text_body == email.text_body
      assert casted_email.headers == email.headers
    end

    test "send/3 actually sends the email" do
      email =
        HaytniWeb.EmailCase.dummy_attributes()
        |> Swoosh.Email.new()
      @adapter.send(email, @mailer, [])

      Swoosh.TestAssertions.assert_email_sent(email)
    end
  end
end
