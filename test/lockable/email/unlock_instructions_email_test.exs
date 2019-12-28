defmodule Haytni.LockableEmail.ResetPasswordEmailTest do
  use ExUnit.Case
  use Bamboo.Test

  describe "Haytni.LockableEmail.unlock_instructions_email/3 (callback)" do
    test "checks unlock email" do
      config = Haytni.LockablePlugin.build_config()
      user = %HaytniTest.User{email: "abc@def.ghi", unlock_token: "S7ViKr4vSYs1"}
      email = Haytni.LockableEmail.unlock_instructions_email(user, HaytniTestWeb.Haytni, config)

      assert email.to == user.email
      assert email.from == HaytniTest.Mailer.from()

      hello_message = "Hello #{user.email}!"
      assert String.contains?(email.text_body, hello_message)
      assert String.contains?(email.html_body, "<p>#{hello_message}</p>")

      href = HaytniTestWeb.Router.Helpers.unlock_url(HaytniTestWeb.Endpoint, :show, unlock_token: user.unlock_token)
      assert String.contains?(email.text_body, href)
      assert String.contains?(email.html_body, "<a href=\"#{href}\">")
    end
  end
end
