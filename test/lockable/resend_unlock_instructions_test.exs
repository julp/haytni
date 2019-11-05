defmodule Haytni.Lockable.ResendUnlockInstructionsTest do
  use HaytniWeb.ConnCase, async: true
  use Bamboo.Test

  alias HaytniTest.User

  describe "Haytni.LockablePlugin.resend_unlock_instructions/1" do
    setup do
      unlocked_account = user_fixture()
      locked_account = user_fixture()
      |> lock_user!("don't care")

      {:ok, locked_request} = Haytni.Unlockable.Request.create_request(%{email: locked_account.email})
      {:ok, unlocked_request} = Haytni.Unlockable.Request.create_request(%{email: unlocked_account.email})
      {:ok, nomatch_request} = Haytni.Unlockable.Request.create_request(%{email: "nomatch"})

      {:ok, locked_account: locked_account, locked_request: locked_request, unlocked_request: unlocked_request, nomatch_request: nomatch_request}
    end

    @strategies ~W[both]a
    #@strategies ~W[none email time both]a # TODO: handle strategy
    @email_strategies ~W[both email]a

    for strategy <- @strategies -- @email_strategies do
      test "returns error when strategy doesn't include email (strategy: #{strategy})", %{locked_request: locked_request, unlocked_request: unlocked_request, nomatch_request: nomatch_request} do
        assert {:error, :email_strategy_disabled} = Haytni.LockablePlugin.resend_unlock_instructions(nomatch_request)
        assert {:error, :email_strategy_disabled} = Haytni.LockablePlugin.resend_unlock_instructions(locked_request)
        assert {:error, :email_strategy_disabled} = Haytni.LockablePlugin.resend_unlock_instructions(unlocked_request)
      end
    end

    for strategy <- ~W[both]a do # TODO: s/~W[both]a/@email_strategies/
      test " (strategy: #{strategy})", %{locked_account: %User{id: id}, locked_request: locked_request} do
        assert {:ok, matched_user = %User{id: ^id}} = Haytni.LockablePlugin.resend_unlock_instructions(locked_request)

        assert_delivered_email Haytni.LockableEmail.unlock_instructions_email(matched_user)
      end

      test "returns error when targetted account is not locked (strategy: #{strategy})", %{unlocked_request: unlocked_request} do
        assert {:error, :not_locked} = Haytni.LockablePlugin.resend_unlock_instructions(unlocked_request)
      end

      test "returns error when there is no match (strategy: #{strategy})", %{nomatch_request: nomatch_request} do
        assert {:error, :no_match} = Haytni.LockablePlugin.resend_unlock_instructions(nomatch_request)
      end
    end
  end
end
