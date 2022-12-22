defmodule Haytni.Lockable.UnlockUserTest do
  use Haytni.DataCase, [
    email: true,
    plugin: Haytni.LockablePlugin,
  ]

  describe "Haytni.LockablePlugin.unlock_user/2" do
    test "an unlocked user stays unlocked" do
      user = user_fixture(locked_at: nil)
      assert is_nil(user.locked_at)

      {:ok, updated_user} = @plugin.unlock_user(HaytniTestWeb.Haytni, user)
      assert is_nil(updated_user.locked_at)
    end

    test "a locked user gets unlocked" do
      user = user_fixture(locked_at: Haytni.Helpers.now())
      %DateTime{} = user.locked_at

      {:ok, updated_user} = @plugin.unlock_user(HaytniTestWeb.Haytni, user)
      assert is_nil(updated_user.locked_at)
    end
  end
end
