defmodule Haytni.Recoverable.SendResetPasswordInstructionsTest do
  use Haytni.DataCase, async: true
  use Bamboo.Test

  @spec create_request(email :: String.t) :: Haytni.params
  defp create_request(email) do
    %{"email" => email}
  end

  describe "Haytni.RecoverablePlugin.send_reset_password_instructions/3" do
    setup do
      _some_random_user = user_fixture()

      {:ok, user: user_fixture(email: "mrvovnhv3l44@test.com"), config: Haytni.RecoverablePlugin.build_config()}
    end

#     @keys [
#       ~W[email]a,
#       ~W[first_name last_name]a,
#     ]
#     for keys <- @keys do
      test "gets error when unlock_keys are empty with email as key(s)", %{config: config} do
        assert {:error, changeset} = Haytni.RecoverablePlugin.send_reset_password_instructions(HaytniTestWeb.Haytni, config, create_request(""))
        refute is_nil(changeset.action)
        assert %{email: [empty_message()]} == errors_on(changeset)
      end

      test "gets error when no one matches with email as key(s)", %{config: config} do
        assert {:error, changeset} = Haytni.RecoverablePlugin.send_reset_password_instructions(HaytniTestWeb.Haytni, config, create_request("not a match"))
        refute is_nil(changeset.action)
        assert %{email: [Haytni.Helpers.no_match_message()]} == errors_on(changeset)
      end

      test "ensures a reset token is generated and sent by email when a user match with email as key(s)", %{config: config, user: user} do
        {:ok, updated_user} = Haytni.RecoverablePlugin.send_reset_password_instructions(HaytniTestWeb.Haytni, config, create_request(user.email))

        assert updated_user.id == user.id
        assert is_binary(updated_user.reset_password_token)
        assert %DateTime{} = updated_user.reset_password_sent_at

        assert_delivered_email Haytni.RecoverableEmail.reset_password_email(updated_user, updated_user.reset_password_token, HaytniTestWeb.Haytni, config)
      end
#     end
  end
end
