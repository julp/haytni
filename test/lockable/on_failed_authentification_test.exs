defmodule Haytni.Lockable.OnFailedAuthentificationTest do
  use HaytniWeb.ConnCase, async: true
  use Bamboo.Test

  alias HaytniTest.User

  defp on_failed_authentication(config, user, multi \\ nil, keywords \\ nil) do
    Haytni.LockablePlugin.on_failed_authentication(user, multi || Ecto.Multi.new(), keywords || Keyword.new(), HaytniTestWeb.Haytni, config)
  end

  describe "Haytni.LockablePlugin.on_failed_authentication/5 (callback)" do
    setup do
      {:ok, config: Haytni.LockablePlugin.build_config()}
    end

    test "ensures failed_attempts is (only) incremented while it doesn't exceed maximum_attempts", %{config: config} do
      user = %User{locked_at: nil, unlock_token: nil, failed_attempts: 0}

      Range.new(0, config.maximum_attempts - 2)
      |> Enum.each(
        fn attempt ->
          {multi, changes} = on_failed_authentication(config, %{user | failed_attempts: attempt})

          assert [] == Ecto.Multi.to_list(multi)
          assert [failed_attempts: attempt + 1] == changes
        end
      )
    end

    for strategy <- Haytni.LockablePlugin.Config.available_strategies() do
      test "ensures account becomes locked if failed_attempts >= maximum_attempts (strategy: #{strategy})", %{config: config} do
        %{config | unlock_strategy: unquote(strategy)}
        # NOTE: user needs an email for email based strategies
        user = %User{email: "test@notadomain.com", locked_at: nil, unlock_token: nil, failed_attempts: 0}

        Range.new(config.maximum_attempts - 1, config.maximum_attempts + 1) # ensures locking takes place even if failed_attempts > maximum_attempts
        |> Enum.each(
          fn attempt ->
            {_multi, changes} = on_failed_authentication(config, %{user | failed_attempts: attempt})
            changes_as_map = Enum.into(changes, %{})

            assert %{locked_at: at, unlock_token: token} = changes_as_map

            assert %DateTime{} = at
            assert is_binary(token)
          end
        )
      end
    end

    for strategy <- Haytni.LockablePlugin.Config.email_strategies() do
      test "ensures an email was sent for strategy #{strategy} when lock happens", %{config: config} do
        config = %{config | unlock_strategy: unquote(strategy)}
        user = %User{email: "test@notadomain.com", failed_attempts: config.maximum_attempts}
        {multi, changes} = on_failed_authentication(config, user)

        updated_user = user
        |> Ecto.Changeset.change(changes)
        |> Ecto.Changeset.apply_changes()

        assert [{:send_unlock_instructions, {:run, fun}}] = Ecto.Multi.to_list(multi)
        assert {:ok, :success} = fun.(HaytniTest.Repo, %{user: updated_user})
        assert_delivered_email Haytni.LockableEmail.unlock_instructions_email(updated_user, HaytniTestWeb.Haytni, config)
      end
    end
  end
end