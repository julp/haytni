defmodule Haytni.LockableEmail.UnlockInstructionsEmailTest do
  use ExUnit.Case
  use Bamboo.Test

  describe "Haytni.LockableEmail.unlock_instructions_email/4 (callback)" do
    test "checks unlock email" do
      token = "azerty"
      config = Haytni.LockablePlugin.build_config()
      user = %HaytniTest.User{email: "abc@def.ghi"}
      email = Haytni.LockableEmail.unlock_instructions_email(user, token, HaytniTestWeb.Haytni, config)

      assert email.to == user.email
      assert email.from == HaytniTest.Mailer.from()

      hello_message = "Hello #{user.email}!"
      assert String.contains?(email.text_body, hello_message)
      assert String.contains?(email.html_body, "<p>#{hello_message}</p>")

      href = HaytniTestWeb.Router.Helpers.haytni_user_unlock_url(HaytniTestWeb.Endpoint, :show, unlock_token: token)
      assert String.contains?(email.text_body, href)
      assert String.contains?(email.html_body, "<a href=\"#{href}\">")
    end
  end
end
