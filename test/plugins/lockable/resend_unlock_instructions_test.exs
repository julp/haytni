defmodule Haytni.Lockable.ResendUnlockInstructionsTest do
  use Haytni.DataCase, [
    email: true,
    plugin: Haytni.LockablePlugin,
  ]

  alias HaytniTest.User

  describe "Haytni.LockablePlugin.resend_unlock_instructions/3" do
    setup do
      unlocked_account = user_fixture()
      locked_account =
        @plugin.lock_attributes()
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
        config = @plugin.build_config(unlock_strategy: unquote(strategy))

        for params <- [nomatch_params, locked_params, unlocked_params] do
          assert {:error, changeset = %Ecto.Changeset{}} = @plugin.resend_unlock_instructions(@stack, config, params)

          refute changeset.valid?
          refute is_nil(changeset.action)
          assert %{base: [@plugin.email_strategy_disabled_message()]} == errors_on(changeset)
        end
      end
    end

    test "returns error when unlock_keys with email as key(s) are empty" do
      config = @plugin.build_config()

      assert {:error, changeset = %Ecto.Changeset{}} = @plugin.resend_unlock_instructions(@stack, config, %{"email" => ""})

      refute changeset.valid?
      refute is_nil(changeset.action)
      assert %{email: [empty_message()]} == errors_on(changeset)
    end

    for strategy <- Haytni.LockablePlugin.Config.email_strategies() do
      test "sends an email when an account is locked (strategy: #{strategy})", %{locked_account: %User{id: id}, locked_params: locked_params} do
        config = @plugin.build_config(unlock_strategy: unquote(strategy))

        assert {:ok, matched_user = %User{id: ^id}} = @plugin.resend_unlock_instructions(@stack, config, locked_params)
        [token] =
          matched_user
          |> Haytni.Token.tokens_from_user_query(@plugin.token_context(nil))
          |> @repo.all()
        matched_user
        |> Haytni.LockableEmail.unlock_instructions_email(Haytni.Token.url_encode(token), @stack, config)
        |> assert_email_sent()
      end

      test "returns {:ok, nil} when targetted account is not locked (strategy: #{strategy})", %{unlocked_params: unlocked_params} do
        config = @plugin.build_config(unlock_strategy: unquote(strategy))

        assert {:ok, nil} = @plugin.resend_unlock_instructions(@stack, config, unlocked_params)
      end

      test "returns {:ok, nil} when there is no match (strategy: #{strategy})", %{nomatch_params: nomatch_params} do
        config = @plugin.build_config(unlock_strategy: unquote(strategy))

        assert {:ok, nil} = @plugin.resend_unlock_instructions(@stack, config, nomatch_params)
      end
    end
  end
end
