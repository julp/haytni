defmodule Haytni.RecoverableEmail.ResetPasswordEmailTest do
  use ExUnit.Case
  use Bamboo.Test

  describe "Haytni.RecoverableEmail.reset_password_email/3 (callback)" do
    test "checks recovery email" do
      config = Haytni.RecoverablePlugin.build_config()
      user = %HaytniTest.User{email: "abc@def.ghi", reset_password_token: "YvLdScEIfwOC"}
      email = Haytni.RecoverableEmail.reset_password_email(user, HaytniTestWeb.Haytni, config)

      assert email.to == user.email
      assert email.from == HaytniTest.Mailer.from()

      hello_message = "Hello #{user.email}!"
      assert String.contains?(email.text_body, hello_message)
      assert String.contains?(email.html_body, "<p>#{hello_message}</p>")

      href = HaytniTestWeb.Router.Helpers.password_url(HaytniTestWeb.Endpoint, :edit, reset_password_token: user.reset_password_token)
      assert String.contains?(email.text_body, href)
      assert String.contains?(email.html_body, "<a href=\"#{href}\">")
    end
  end
end