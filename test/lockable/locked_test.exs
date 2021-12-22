defmodule Haytni.Lockable.LockedTest do
  use Haytni.DataCase, async: true

  alias HaytniTest.User

  @delay 8
  describe "Haytni.LockablePlugin.locked?/2" do
    setup do
      config = Haytni.LockablePlugin.build_config()

      unlocked = %User{locked_at: nil}
      expired = %User{locked_at: seconds_ago(config.unlock_in - @delay)}
      unexpired = %User{locked_at: seconds_ago(config.unlock_in + @delay)}

      [
        config: config,
        unlocked: unlocked,
        expired: expired,
        unexpired: unexpired,
      ]
    end

    for strategy <- Haytni.LockablePlugin.Config.available_strategies() do
      test "ensures non-locked account is not invalid (strategy: #{strategy})", %{config: config, unlocked: unlocked} do
        refute Haytni.LockablePlugin.locked?(unlocked, config)
      end
    end

    test "ensures locked account is invalid (strategy: none)", %{config: config, expired: expired, unexpired: unexpired} do
      config = %{config | unlock_strategy: :none}

      assert Haytni.LockablePlugin.locked?(expired, config)
      assert Haytni.LockablePlugin.locked?(unexpired, config)
    end

    test "ensures locked account is invalid (strategy: time)", %{config: config, expired: expired, unexpired: unexpired} do
      config = %{config | unlock_strategy: :time}

      assert Haytni.LockablePlugin.locked?(expired, config)
      refute Haytni.LockablePlugin.locked?(unexpired, config)
    end

    test "ensures locked account is invalid (strategy: email)", %{config: config, expired: expired, unexpired: unexpired} do
      config = %{config | unlock_strategy: :email}

      assert Haytni.LockablePlugin.locked?(expired, config)
      assert Haytni.LockablePlugin.locked?(unexpired, config)
    end

    test "ensures locked account is invalid (strategy: both)", %{config: config, expired: expired, unexpired: unexpired} do
      config = %{config | unlock_strategy: :both}

      assert Haytni.LockablePlugin.locked?(expired, config)
      refute Haytni.LockablePlugin.locked?(unexpired, config)
    end
  end
end
