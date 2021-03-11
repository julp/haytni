defmodule Haytni.InvitableEmail.InvitationEmailTest do
  use ExUnit.Case
  use Bamboo.Test

  describe "Haytni.InvitableEmail.invitation_email/4 (callback)" do
    test "checks invitation email" do
      config = Haytni.InvitablePlugin.build_config()
      user = %HaytniTest.User{email: "sender@domain.com"}
      invitation = Haytni.InvitablePlugin.build_and_assoc_invitation(user, code: "0123456789", sent_to: "receiver@domain.com")
      email = Haytni.InvitableEmail.invitation_email(user, invitation, HaytniTestWeb.Haytni, config)

      assert email.to == invitation.sent_to
      assert email.from == HaytniTest.Mailer.from()

      hello_message = "Hello #{invitation.sent_to}!"
      assert email.text_body =~ hello_message
      assert email.html_body =~ "<p>#{hello_message}</p>"

      href = HaytniTestWeb.Router.Helpers.haytni_user_registration_url(HaytniTestWeb.Endpoint, :new, invitation: invitation.code, email: invitation.sent_to)
      assert email.text_body =~ href
      assert Haytni.TestHelpers.contains_text?(email.html_body, href)
    end
  end
end
