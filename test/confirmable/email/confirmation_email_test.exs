defmodule Haytni.ConfirmableEmail.ConfirmationEmailTest do
  use ExUnit.Case
  use Bamboo.Test

  describe "Haytni.ConfirmableEmail.confirmation_email/3 (callback)" do
    test "checks confirmation email" do
      config = Haytni.ConfirmablePlugin.build_config()
      user = %HaytniTest.User{email: "abc@def.ghi", confirmation_token: "rkSItvu38fjb"}
      email = Haytni.ConfirmableEmail.confirmation_email(user, HaytniTestWeb.Haytni, config)

      assert email.to == user.email
      assert email.from == HaytniTest.Mailer.from()

      welcome_message = "Welcome #{user.email},"
      assert String.contains?(email.text_body, welcome_message)
      assert String.contains?(email.html_body, "<p>#{welcome_message}</p>")

      href = HaytniTestWeb.Router.Helpers.haytni_user_confirmation_url(HaytniTestWeb.Endpoint, :show, confirmation_token: user.confirmation_token)
      assert String.contains?(email.text_body, href)
      assert String.contains?(email.html_body, "<a href=\"#{href}\">")
    end
  end
end
