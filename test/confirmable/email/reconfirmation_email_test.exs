defmodule Haytni.ConfirmableEmail.ReconfirmationEmailTest do
  use ExUnit.Case
  use Bamboo.Test

  describe "Haytni.ConfirmableEmail.reconfirmation_email/5" do
    test "checks confirmation email" do
      unconfirmed_email = "abc@def.ghi"
      config = Haytni.ConfirmablePlugin.build_config()
      user = %HaytniTest.User{unconfirmed_email: unconfirmed_email, confirmation_token: "eBfPHalAkSbp"}
      email = Haytni.ConfirmableEmail.reconfirmation_email(user, unconfirmed_email, user.confirmation_token, HaytniTestWeb.Haytni, config)

      assert email.to == unconfirmed_email
      assert email.from == HaytniTest.Mailer.from()

      welcome_message = "Hi #{unconfirmed_email},"
      assert email.text_body =~ welcome_message
      assert email.html_body =~ "<p>#{welcome_message}</p>"

      href = HaytniTestWeb.Router.Helpers.haytni_user_confirmation_url(HaytniTestWeb.Endpoint, :show, confirmation_token: user.confirmation_token)
      assert email.text_body =~ href
      assert email.html_body =~ "<a href=\"#{href}\">"
    end
  end
end
