defmodule Haytni.Lockable.LockUserTest do
  use Haytni.DataCase, async: true

  describe "Haytni.LockablePlugin.lock_user/2" do
    test "an unlocked user gets locked" do
      user = user_fixture(locked_at: nil)
      assert is_nil(user.locked_at)

      {:ok, updated_user} = Haytni.LockablePlugin.lock_user(HaytniTestWeb.Haytni, user)
      %DateTime{} = updated_user.locked_at
    end

    test "a locked user stays locked" do
      user = user_fixture(locked_at: Haytni.Helpers.now())
      %DateTime{} = user.locked_at

      {:ok, updated_user} = Haytni.LockablePlugin.lock_user(HaytniTestWeb.Haytni, user)
      %DateTime{} = updated_user.locked_at
    end
  end
end
