defmodule Haytni.ConfirmableEmail.ConfirmationEmailTest do
  use ExUnit.Case
  use Bamboo.Test

  describe "Haytni.ConfirmableEmail.confirmation_email/4 (callback)" do
    test "checks confirmation email" do
      confirmation_token = "AJRMQrmOXh"
      config = Haytni.ConfirmablePlugin.build_config()
      user = %HaytniTest.User{email: "abc@def.ghi"}
      email = Haytni.ConfirmableEmail.confirmation_email(user, confirmation_token, HaytniTestWeb.Haytni, config)

      assert email.to == user.email
      assert email.from == HaytniTest.Mailer.from()

      welcome_message = "Welcome #{user.email},"
      assert email.text_body =~ welcome_message
      assert email.html_body =~ "<p>#{welcome_message}</p>"

      href = HaytniTestWeb.Router.Helpers.haytni_user_confirmation_url(HaytniTestWeb.Endpoint, :show, confirmation_token: confirmation_token)
      assert email.text_body =~ href
      assert email.html_body =~ "<a href=\"#{href}\">"
    end
  end
end
