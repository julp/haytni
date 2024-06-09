defmodule Haytni.Recoverable.SendResetPasswordInstructionsTest do
  use Haytni.DataCase, [
    email: true,
    plugin: Haytni.RecoverablePlugin,
  ]

  @spec create_request(email :: String.t) :: Haytni.params
  defp create_request(email) do
    %{"email" => email}
  end

  describe "Haytni.RecoverablePlugin.send_reset_password_instructions/3" do
    setup do
      _some_random_user = user_fixture()

      [
        config: @plugin.build_config(),
        user: user_fixture(email: "mrvovnhv3l44@test.com"),
      ]
    end

#     @keys [
#       ~W[email]a,
#       ~W[first_name last_name]a,
#     ]
#     for keys <- @keys do
      test "gets error when unlock_keys are empty with email as key(s)", %{config: config} do
        assert {:error, changeset} = @plugin.send_reset_password_instructions(@stack, config, create_request(""))
        refute is_nil(changeset.action)
        assert %{email: [empty_message()]} == errors_on(changeset)
      end

      test "gets {:ok, nil} when no one matches with email as key(s)", %{config: config} do
        assert {:ok, nil} == @plugin.send_reset_password_instructions(@stack, config, create_request("not a match"))
      end

      test "ensures a reset token is generated and sent by email when a user match with email as key(s)", %{config: config, user: user} do
        {:ok, token} = @plugin.send_reset_password_instructions(@stack, config, create_request(user.email))

        assert token.user_id == user.id
        user
        |> Haytni.RecoverableEmail.reset_password_email(Haytni.Token.url_encode(token), @stack, config)
        |> assert_email_sent()
      end
#     end
  end
end
