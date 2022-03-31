defmodule Haytni.Lockable.UnlockUserTest do
  use Haytni.DataCase, async: true

  describe "Haytni.LockablePlugin.unlock_user/2" do
    test "an unlocked user stays unlocked" do
      user = user_fixture(locked_at: nil)
      assert is_nil(user.locked_at)

      {:ok, updated_user} = Haytni.LockablePlugin.unlock_user(HaytniTestWeb.Haytni, user)
      assert is_nil(updated_user.locked_at)
    end

    test "a locked user gets unlocked" do
      user = user_fixture(locked_at: Haytni.Helpers.now())
      %DateTime{} = user.locked_at

      {:ok, updated_user} = Haytni.LockablePlugin.unlock_user(HaytniTestWeb.Haytni, user)
      assert is_nil(updated_user.locked_at)
    end
  end
end
