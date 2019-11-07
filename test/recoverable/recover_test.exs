defmodule Haytni.Recoverable.RecoverTest do
  use Haytni.DataCase, async: true

  alias HaytniTest.User

  describe "Haytni.RecoverablePlugin.recover/2" do
    setup do
      _some_random_guy = user_fixture()

      user = user_fixture()
      |> Haytni.update_user_with!(reset_password_token: "4pEW1QkmvJJbnhVC", reset_password_sent_at: Haytni.now())

      {:ok, user: user}
    end

    test "ensures error when reset token doesn't exist" do
      assert {:error, reason} = Haytni.RecoverablePlugin.recover("not a match", "unused new password")
      assert reason =~ ~R/invalid/i
    end

    test "ensures error when reset token has expired (and password remains the same)", %{user: user = %User{id: id, encrypted_password: encrypted_password}} do
      new_reset_password_sent_at = Haytni.RecoverablePlugin.reset_password_within()
      |> Haytni.duration()
      |> Kernel.+(1)
      |> seconds_ago()

      user = Haytni.update_user_with!(user, reset_password_sent_at: new_reset_password_sent_at)

      assert {:error, reason} = Haytni.RecoverablePlugin.recover(user.reset_password_token, "unused new password")
      assert reason =~ ~R/expired/i
      # ensure password hasn't changed
      assert %User{id: ^id, encrypted_password: ^encrypted_password} = Haytni.Users.get_user!(id)
    end

    @new_password "this is my new password"
    test "ensures password was reseted in normal condition", %{user: user} do
      assert updated_user = %User{} = Haytni.RecoverablePlugin.recover(user.reset_password_token, @new_password)

      assert updated_user.id == user.id
      assert is_nil(updated_user.reset_password_token)
      assert is_nil(updated_user.reset_password_sent_at)
      assert String.starts_with?(updated_user.encrypted_password, "$2b$")
      assert Haytni.AuthenticablePlugin.check_password(updated_user, @new_password)
    end
  end
end
