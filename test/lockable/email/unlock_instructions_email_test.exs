defmodule Haytni.LockableEmail.UnlockInstructionsEmailTest do
  use HaytniWeb.EmailCase, [
    async: true,
    plugin: Haytni.LockablePlugin,
  ]

  describe "Haytni.LockableEmail.unlock_instructions_email/4 (callback)" do
    test "checks unlock email" do
      token = "azerty"
      config = @plugin.build_config()
      user = %HaytniTest.User{email: "abc@def.ghi"}
      email = Haytni.LockableEmail.unlock_instructions_email(user, token, @stack, config)

      assert email.to == user.email
      assert email.from == @mailer.from()

      hello_message = "Hello #{user.email}!"
      assert email.text_body =~ hello_message
      assert email.html_body =~ "<p>#{hello_message}</p>"

      href = HaytniTestWeb.Router.Helpers.haytni_user_unlock_url(@endpoint, :show, unlock_token: token)
      assert email.text_body =~ href
      assert email.html_body =~ "<a href=\"#{href}\">"
    end
  end
end
