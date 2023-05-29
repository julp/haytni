defmodule Hayni.Mail.BambooAdapterTest do
  use HaytniWeb.EmailCase, [
    email: true,
  ]

  describe "Haytni.Mailer.BambooAdapter" do
    test "cast/3 returns a %Bamboo.Email{}" do
      email = HaytniWeb.EmailCase.dummy_email(@stack)
      casted_email = @adapter.cast(email, @mailer, [])

      assert casted_email.__struct__ == Bamboo.Email
      assert casted_email.to == email.to
      assert casted_email.subject == email.subject
      assert casted_email.html_body == email.html_body
      assert casted_email.text_body == email.text_body
      assert casted_email.headers == email.headers
    end

    test "send/3 actually sends the email" do
      email =
        HaytniWeb.EmailCase.dummy_attributes()
        |> Bamboo.Email.new_email()
      @adapter.send(email, @mailer, [])

      assert_delivered_email(email)
    end
  end
end
