defmodule Haytni.Lockable.UnlockedTest do
  use HaytniWeb.ConnCase, async: true

  alias HaytniTest.User

  @unlock_token "ABCDE"
  describe "Haytni.LockablePlugin.unlock/1" do
    setup do
      _unlocked = user_fixture() # to not just have an unlocked user in the database

      locked = user_fixture()
      |> lock_user!(@unlock_token)
      #|> Ecto.Changeset.change(unlock_token: @unlock_token, locked_at: ~U[1970-01-01 00:00:00Z], failed_attempts: 100)
      #|> Haytni().repo().update!()

      {:ok, locked: locked}
    end

    @strategies ~W[both]a
    #@strategies ~W[none email time both]a # TODO: handle strategy
    @email_strategies ~W[both email]a

    for strategy <- @strategies do
      test "returns an error when token doesn't match anything (strategy: #{strategy})" do
        assert {:error, _reason} = Haytni.LockablePlugin.unlock("not a match")
      end
    end

    for strategy <- @strategies -- @email_strategies do
      test "returns error when strategy doesn't include email (strategy: #{strategy})" do
        assert {:error, _reason} = Haytni.LockablePlugin.unlock(@unlock_token)
      end
    end

    for strategy <- ~W[both]a do # TODO: s/~W[both]a/@email_strategies/
      test "returns updated and unlocked user after unlock (strategy: #{strategy})", %{locked: %User{id: id}} do
        assert updated_user = %User{id: ^id} = Haytni.LockablePlugin.unlock(@unlock_token)
        # assert lock was reseted
        assert updated_user.locked_at == nil
        assert updated_user.failed_attempts == 0
      end
    end
  end
end
