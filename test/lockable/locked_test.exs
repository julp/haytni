defmodule Haytni.Lockable.LockedTest do
  use HaytniWeb.ConnCase, async: true

  alias HaytniTest.User

  @delay 8
  describe "Haytni.LockablePlugin.locked?/2" do
    setup do
      unlocked = %User{locked_at: nil}
      expired = %User{locked_at: seconds_ago(Haytni.duration(Haytni.LockablePlugin.unlock_in()) + @delay)}
      unexpired = %User{locked_at: seconds_ago(Haytni.duration(Haytni.LockablePlugin.unlock_in()) - @delay)}

      {:ok, unlocked: unlocked, expired: expired, unexpired: unexpired}
    end

    test "ensures non-locked account is not invalid (strategy: none)", %{unlocked: unlocked} do
      refute Haytni.LockablePlugin.locked?(unlocked, :none)
    end

    test "ensures locked account is invalid (strategy: none)", %{expired: expired, unexpired: unexpired} do
      assert Haytni.LockablePlugin.locked?(expired, :none)
      assert Haytni.LockablePlugin.locked?(unexpired, :none)
    end

    test "ensures non-locked account is not invalid (strategy: time)", %{unlocked: unlocked} do
      refute Haytni.LockablePlugin.locked?(unlocked, :time)
    end

    test "ensures locked account is invalid (strategy: time)", %{expired: expired, unexpired: unexpired} do
      refute Haytni.LockablePlugin.locked?(expired, :time)
      assert Haytni.LockablePlugin.locked?(unexpired, :time)
    end

    test "ensures non-locked account is not invalid (strategy: email)", %{unlocked: unlocked} do
      refute Haytni.LockablePlugin.locked?(unlocked, :email)
    end

    test "ensures locked account is invalid (strategy: email)", %{expired: expired, unexpired: unexpired} do
      assert Haytni.LockablePlugin.locked?(expired, :email)
      assert Haytni.LockablePlugin.locked?(unexpired, :email)
    end

    test "ensures non-locked account is not invalid (strategy: both)", %{unlocked: unlocked} do
      refute Haytni.LockablePlugin.locked?(unlocked, :both)
    end

    test "ensures locked account is invalid (strategy: both)", %{expired: expired, unexpired: unexpired} do
      refute Haytni.LockablePlugin.locked?(expired, :both)
      assert Haytni.LockablePlugin.locked?(unexpired, :both)
    end
  end
end
