defmodule Haytni.Recoverable.ResendConfirmationInstructionsTest do
  use Haytni.DataCase, async: true
  use Bamboo.Test#, shared: true

  @spec create_confirmation(email :: String.t) :: %{String.t => String.t}
  defp create_confirmation(email) do
    %{
      "email" => email,
      "referer" => "http://www.test.com/",
    }
  end

  describe "Haytni.ConfirmablePlugin.resend_confirmation_instructions/3" do
    setup do
      config = Haytni.ConfirmablePlugin.build_config()
      confirmed_user = user_fixture()
      unconfirmed_user =
        config
        |> Haytni.ConfirmablePlugin.new_confirmation_attributes()
        |> user_fixture()

      [
        config: config,
        confirmed_user: confirmed_user,
        unconfirmed_user: unconfirmed_user,
      ]
    end

    test "ensures no email is sent if email as confirmation keys are empty", %{config: config} do
      assert {:error, changeset} = Haytni.ConfirmablePlugin.resend_confirmation_instructions(HaytniTestWeb.Haytni, config, create_confirmation(""))
      refute is_nil(changeset.action)
      assert %{email: [empty_message()]} == errors_on(changeset)
      assert_no_emails_delivered()
    end

    test "ensures no email is sent if no one (email) match", %{config: config} do
      assert {:error, changeset} = Haytni.ConfirmablePlugin.resend_confirmation_instructions(HaytniTestWeb.Haytni, config, create_confirmation("no match"))
      refute is_nil(changeset.action)
      assert %{email: [Haytni.Helpers.no_match_message()]} == errors_on(changeset)
      assert_no_emails_delivered()
    end

    test "ensures no email is sent if account is already confirmed", %{config: config, confirmed_user: confirmed_user} do
      assert {:error, changeset} = Haytni.ConfirmablePlugin.resend_confirmation_instructions(HaytniTestWeb.Haytni, config, create_confirmation(confirmed_user.email))
      refute is_nil(changeset.action)
      assert %{email: [Haytni.ConfirmablePlugin.alreay_confirmed_message()]} == errors_on(changeset)
      assert_no_emails_delivered()
    end

    test "ensures a new confirmation is sent by email with the same token if last one is not expired", %{config: config, unconfirmed_user: user} do
      assert {:ok, updated_user} = Haytni.ConfirmablePlugin.resend_confirmation_instructions(HaytniTestWeb.Haytni, config, create_confirmation(user.email))
      assert updated_user.id == user.id
      assert_delivered_email Haytni.ConfirmableEmail.confirmation_email(user, user.confirmation_token, HaytniTestWeb.Haytni, config)
    end

    test "ensures a new confirmation is sent by email with the a new token if last one is expired", %{config: config, unconfirmed_user: user} do
      new_confirmation_sent_at =
        config.confirm_within
        |> Kernel.+(1)
        |> seconds_ago()

      expired_user =
        user
        |> Ecto.Changeset.change(confirmation_sent_at: new_confirmation_sent_at)
        |> HaytniTest.Repo.update!()

      {:ok, updated_user} = Haytni.ConfirmablePlugin.resend_confirmation_instructions(HaytniTestWeb.Haytni, config, create_confirmation(user.email))

      assert updated_user.id == user.id
      refute updated_user.confirmation_token == expired_user.confirmation_token
      refute updated_user.confirmation_sent_at == expired_user.confirmation_sent_at
      assert_delivered_email Haytni.ConfirmableEmail.confirmation_email(updated_user, updated_user.confirmation_token, HaytniTestWeb.Haytni, config)
    end
  end
end
