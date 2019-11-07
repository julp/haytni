defmodule Haytni.Recoverable.SendResetPasswordInstructionsTest do
  use Haytni.DataCase, async: true
  use Bamboo.Test

  @spec create_request(email :: String.t) :: Haytni.Recoverable.ResetRequest.t
  defp create_request(email) do
    {:ok, request} = Haytni.Recoverable.ResetRequest.create_request(%{email: email})
    request
  end

  describe "Haytni.RecoverablePlugin.send_reset_password_instructions/1" do
    setup do
      _some_random_user = user_fixture()

      {:ok, user: user_fixture(email: "mrvovnhv3l44@test.com")}
    end

    test "gets error when no one matches" do
      result = create_request("not a match")
      |> Haytni.RecoverablePlugin.send_reset_password_instructions()

      assert {:error, :no_match} == result
    end

    test "ensures a reset token is generated and sent by email when a user match", %{user: user} do
      {:ok, updated_user} = create_request(user.email)
      |> Haytni.RecoverablePlugin.send_reset_password_instructions()

      assert updated_user.id == user.id
      assert is_binary(updated_user.reset_password_token)
      assert %DateTime{} = updated_user.reset_password_sent_at

      assert_delivered_email Haytni.RecoverableEmail.reset_password_email(updated_user)
    end
  end
end
