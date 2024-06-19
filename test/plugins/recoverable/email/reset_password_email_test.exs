defmodule Haytni.RecoverableEmail.ResetPasswordEmailTest do
  use HaytniWeb.EmailCase, [
    async: true,
    plugin: Haytni.RecoverablePlugin,
  ]

  describe "Haytni.RecoverableEmail.reset_password_email/3 (callback)" do
    test "checks recovery email" do
      token = "qwerty"
      config = @plugin.build_config()
      user = %HaytniTest.User{email: "abc@def.ghi"}
      email = Haytni.RecoverableEmail.reset_password_email(user, token, @stack, config)

      assert email.to == [user.email]
      assert email.from == @mailer.from()

      hello_message = "Hello #{user.email}!"
      assert email.text_body =~ hello_message
      assert email.html_body =~ "<p>#{hello_message}</p>"

      href = HaytniTestWeb.Router.Helpers.haytni_user_password_url(@endpoint, :edit, reset_password_token: token)
      assert email.text_body =~ href
      assert email.html_body =~ "<a href=\"#{href}\">"
    end
  end
end
