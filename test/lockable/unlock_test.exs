defmodule Haytni.Lockable.UnlockedTest do
  use Haytni.DataCase, async: true

  describe "Haytni.LockablePlugin.unlock/3" do
    setup do
      _unlocked = user_fixture() # to not just have an unlocked user in the database

      locked = Haytni.LockablePlugin.build_config()
      |> Haytni.LockablePlugin.lock_attributes()
      |> user_fixture()

      {:ok, locked: locked}
    end

    for strategy <- Haytni.LockablePlugin.Config.available_strategies() do
      test "returns an error when token doesn't match anything (strategy: #{strategy})" do
        config = Haytni.LockablePlugin.build_config(unlock_strategy: unquote(strategy))
        reason = if Haytni.LockablePlugin.email_strategy_enabled?(config) do
          Haytni.LockablePlugin.invalid_token_message()
        else
          # email strategy disabled supersedes invalidity
          Haytni.LockablePlugin.email_strategy_disabled_message()
        end

        assert {:error, reason} == Haytni.LockablePlugin.unlock(HaytniTestWeb.Haytni, config, "not a match")
      end
    end

    for strategy <- Haytni.LockablePlugin.Config.available_strategies() -- Haytni.LockablePlugin.Config.email_strategies() do
      test "returns error when strategy doesn't include email (strategy: #{strategy})", %{locked: locked} do
        config = Haytni.LockablePlugin.build_config(unlock_strategy: unquote(strategy))

        assert {:error, Haytni.LockablePlugin.email_strategy_disabled_message()} == Haytni.LockablePlugin.unlock(HaytniTestWeb.Haytni, config, locked.unlock_token)
      end
    end

    for strategy <- Haytni.LockablePlugin.Config.email_strategies() do
      test "returns updated and unlocked user after unlock (strategy: #{strategy})", %{locked: locked} do
        config = Haytni.LockablePlugin.build_config(unlock_strategy: unquote(strategy))

        assert {:ok, updated_user} = Haytni.LockablePlugin.unlock(HaytniTestWeb.Haytni, config, locked.unlock_token)
        assert updated_user.id == locked.id
        # assert lock was reseted
        assert is_nil(updated_user.locked_at)
        assert updated_user.failed_attempts == 0
      end
    end
  end
end
