defmodule Haytni.Lockable.UnlockedTest do
  use Haytni.DataCase, [
    email: true,
    plugin: Haytni.LockablePlugin,
  ]

  describe "Haytni.LockablePlugin.unlock/3" do
    setup do
      _unlocked = user_fixture() # to not just have an unlocked user in the database

      locked =
        @plugin.lock_attributes()
        |> user_fixture()

      token =
        locked
        |> token_fixture(@plugin)
        |> Haytni.Token.url_encode()

      [
        token: token,
        locked: locked,
      ]
    end

    for strategy <- Haytni.LockablePlugin.available_strategies() do
      test "returns an error when token doesn't match anything (strategy: #{strategy})" do
        config = @plugin.build_config(unlock_strategy: unquote(strategy))
        reason = if @plugin.email_strategy_enabled?(config) do
          @plugin.invalid_token_message()
        else
          # email strategy disabled supersedes invalidity
          @plugin.email_strategy_disabled_message()
        end

        assert {:error, reason} == @plugin.unlock(@stack, config, "not a match")
      end
    end

    for strategy <- Haytni.LockablePlugin.available_strategies() -- Haytni.LockablePlugin.email_strategies() do
      test "returns error when strategy doesn't include email (strategy: #{strategy})", %{token: unlock_token} do
        config = @plugin.build_config(unlock_strategy: unquote(strategy))

        assert {:error, @plugin.email_strategy_disabled_message()} == @plugin.unlock(@stack, config, unlock_token)
      end
    end

    for strategy <- Haytni.LockablePlugin.email_strategies() do
      test "returns updated and unlocked user after unlock (strategy: #{strategy})", %{locked: locked, token: unlock_token} do
        config = @plugin.build_config(unlock_strategy: unquote(strategy))

        assert {:ok, updated_user} = @plugin.unlock(@stack, config, unlock_token)
        assert updated_user.id == locked.id
        # assert lock was reseted
        assert is_nil(updated_user.locked_at)
        assert updated_user.failed_attempts == 0
      end
    end
  end
end
