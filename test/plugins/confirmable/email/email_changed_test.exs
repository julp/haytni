defmodule Haytni.ConfirmableEmail.EmailChangedTest do
  use HaytniWeb.EmailCase, [
    async: true,
    plugin: Haytni.ConfirmablePlugin,
  ]

  @old_address "foo@bar.com"
  describe "Haytni.ConfirmableEmail.email_changed/4 (callback)" do
    for reconfirmable <- [true, false] do
      test "checks email change notice (reconfirmable = #{reconfirmable})" do
        config = @plugin.build_config(reconfirmable: unquote(reconfirmable))
        user = %HaytniTest.User{email: "abc@def.ghi"}
        email = Haytni.ConfirmableEmail.email_changed(user, @old_address, @stack, config)

        assert email.to == [@old_address]
        assert email.from == @mailer.from()

        welcome_message = "Hello #{@old_address}!"
        assert email.text_body =~ welcome_message
        assert email.html_body =~ "<p>#{welcome_message}</p>"

        expected_email = user.email
        change_message = "changed to #{expected_email}"
        assert email.text_body =~ change_message
        assert email.html_body =~ change_message
      end
    end
  end
end
