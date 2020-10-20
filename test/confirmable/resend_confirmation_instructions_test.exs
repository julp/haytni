defmodule Haytni.Recoverable.ResendConfirmationInstructionsTest do
  use Haytni.DataCase, async: true
  use Bamboo.Test#, shared: true

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
        Haytni.ConfirmablePlugin.confirmed_attributes()
        |> user_fixture()

      [
        confirmed_user: confirmed_user,
        unconfirmed_user: user_fixture(),
        config: Haytni.ConfirmablePlugin.build_config(),
      ]
    end

    test "ensures no email is sent if email as confirmation keys are empty", %{config: config} do
      assert {:error, changeset} = Haytni.ConfirmablePlugin.resend_confirmation_instructions(HaytniTestWeb.Haytni, config, create_confirmation(""))
      refute is_nil(changeset.action)
      assert %{email: [empty_message()]} == errors_on(changeset)
      assert_no_emails_delivered()
    end

    test "ensures no email is sent if no one (email) match", %{config: config} do
      assert {:error, _failed_operation_name, changeset, _changes} = Haytni.ConfirmablePlugin.resend_confirmation_instructions(HaytniTestWeb.Haytni, config, create_confirmation("no match"))
      refute is_nil(changeset.action)
      assert %{email: [Haytni.Helpers.no_match_message()]} == errors_on(changeset)
      assert_no_emails_delivered()
    end

    test "ensures no email is sent if account is already confirmed", %{config: config, confirmed_user: confirmed_user} do
      assert {:error, :user, changeset, %{}} = Haytni.ConfirmablePlugin.resend_confirmation_instructions(HaytniTestWeb.Haytni, config, create_confirmation(confirmed_user.email))
      refute is_nil(changeset.action)
      assert %{email: [Haytni.ConfirmablePlugin.alreay_confirmed_message()]} == errors_on(changeset)
      assert_no_emails_delivered()
    end

    test "ensures a new confirmation is sent by email if account is not already confirmed", %{config: config, unconfirmed_user: user} do
      assert {:ok, %{user: updated_user, token: confirmation_token}} = Haytni.ConfirmablePlugin.resend_confirmation_instructions(HaytniTestWeb.Haytni, config, create_confirmation(user.email))
      assert updated_user.id == user.id
      assert_delivered_email Haytni.ConfirmableEmail.confirmation_email(user, Haytni.Token.encode_token(confirmation_token), HaytniTestWeb.Haytni, config)
    end
  end
end
