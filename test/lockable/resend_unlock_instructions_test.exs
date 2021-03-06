defmodule Haytni.Lockable.ResendUnlockInstructionsTest do
  use Haytni.DataCase, async: true
  use Bamboo.Test

  alias HaytniTest.User

  describe "Haytni.LockablePlugin.resend_unlock_instructions/3" do
    setup do
      unlocked_account = user_fixture()
      locked_account =
        Haytni.LockablePlugin.lock_attributes()
        |> user_fixture()

      locked_params = %{"email" => locked_account.email}
      unlocked_params = %{"email" => unlocked_account.email}
      nomatch_params = %{"email" => "nomatch"}

      [
        locked_account: locked_account,
        locked_params: locked_params,
        unlocked_params: unlocked_params,
        nomatch_params: nomatch_params,
      ]
    end

    for strategy <- Haytni.LockablePlugin.Config.available_strategies() -- Haytni.LockablePlugin.Config.email_strategies() do
      test "returns error when strategy doesn't include email (strategy: #{strategy})", %{locked_params: locked_params, unlocked_params: unlocked_params, nomatch_params: nomatch_params} do
        config = Haytni.LockablePlugin.build_config(unlock_strategy: unquote(strategy))

        for params <- [nomatch_params, locked_params, unlocked_params] do
          assert {:error, changeset = %Ecto.Changeset{}} = Haytni.LockablePlugin.resend_unlock_instructions(HaytniTestWeb.Haytni, config, params)

          refute changeset.valid?
          refute is_nil(changeset.action)
          assert %{base: [Haytni.LockablePlugin.email_strategy_disabled_message()]} == errors_on(changeset)
        end
      end
    end

    test "returns error when unlock_keys with email as key(s) are empty" do
      config = Haytni.LockablePlugin.build_config()

      assert {:error, changeset = %Ecto.Changeset{}} = Haytni.LockablePlugin.resend_unlock_instructions(HaytniTestWeb.Haytni, config, %{"email" => ""})

      refute changeset.valid?
      refute is_nil(changeset.action)
      assert %{email: [empty_message()]} == errors_on(changeset)
    end

    for strategy <- Haytni.LockablePlugin.Config.email_strategies() do
      test "sends an email when an account is locked (strategy: #{strategy})", %{locked_account: %User{id: id}, locked_params: locked_params} do
        config = Haytni.LockablePlugin.build_config(unlock_strategy: unquote(strategy))

        assert {:ok, matched_user = %User{id: ^id}} = Haytni.LockablePlugin.resend_unlock_instructions(HaytniTestWeb.Haytni, config, locked_params)
        [token] =
          matched_user
          |> Haytni.Token.tokens_from_user_query(Haytni.LockablePlugin.token_context(nil))
          |> HaytniTest.Repo.all()
        assert_delivered_email Haytni.LockableEmail.unlock_instructions_email(matched_user, Haytni.Token.url_encode(token), HaytniTestWeb.Haytni, config)
      end

      test "returns {:ok, nil} when targetted account is not locked (strategy: #{strategy})", %{unlocked_params: unlocked_params} do
        config = Haytni.LockablePlugin.build_config(unlock_strategy: unquote(strategy))

        assert {:ok, nil} = Haytni.LockablePlugin.resend_unlock_instructions(HaytniTestWeb.Haytni, config, unlocked_params)
      end

      test "returns {:ok, nil} when there is no match (strategy: #{strategy})", %{nomatch_params: nomatch_params} do
        config = Haytni.LockablePlugin.build_config(unlock_strategy: unquote(strategy))

        assert {:ok, nil} = Haytni.LockablePlugin.resend_unlock_instructions(HaytniTestWeb.Haytni, config, nomatch_params)
      end
    end
  end
end
