defmodule Haytni.Recoverable.ResendConfirmationInstructionsTest do
  use Haytni.DataCase, [
    email: true,
    plugin: Haytni.ConfirmablePlugin,
  ]

  @spec create_confirmation(email :: String.t) :: Haytni.params
  defp create_confirmation(email) do
    %{
      "email" => email,
      "referer" => "http://www.test.com/",
    }
  end

  describe "Haytni.ConfirmablePlugin.resend_confirmation_instructions/3" do
    setup do
      confirmed_user =
        @plugin.confirmed_attributes()
        |> user_fixture()

      [
        confirmed_user: confirmed_user,
        unconfirmed_user: user_fixture(),
        config: @plugin.build_config(),
      ]
    end

    test "ensures no email is sent if email as confirmation keys are empty", %{config: config} do
      assert {:error, changeset} = @plugin.resend_confirmation_instructions(@stack, config, create_confirmation(""))
      refute is_nil(changeset.action)
      assert %{email: [empty_message()]} == errors_on(changeset)
      assert_no_emails_delivered()
    end

    test "ensures no email is sent if no one (email) match", %{config: config} do
      assert {:ok, nil} == @plugin.resend_confirmation_instructions(@stack, config, create_confirmation("no match"))
      assert_no_emails_delivered()
    end

    test "ensures no email is sent if account is already confirmed", %{config: config, confirmed_user: confirmed_user} do
      assert {:ok, nil} == @plugin.resend_confirmation_instructions(@stack, config, create_confirmation(confirmed_user.email))
      assert_no_emails_delivered()
    end

    test "ensures a new confirmation is sent by email if account is not already confirmed", %{config: config, unconfirmed_user: user} do
      assert {:ok, confirmation_token} = @plugin.resend_confirmation_instructions(@stack, config, create_confirmation(user.email))
      assert confirmation_token.user_id == user.id
      user
      |> Haytni.ConfirmableEmail.confirmation_email(Haytni.Token.url_encode(confirmation_token), @stack, config)
      |> assert_email_was_sent()
    end
  end
end
