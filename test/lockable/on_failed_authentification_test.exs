defmodule Haytni.Lockable.OnFailedAuthentificationTest do
  use HaytniWeb.ConnCase, async: true
  use Bamboo.Test

  alias HaytniTest.User

  defp on_failed_authentication(config, user, multi \\ nil, keywords \\ nil) do
    Haytni.LockablePlugin.on_failed_authentication(user, multi || Ecto.Multi.new(), keywords || Keyword.new(), HaytniTestWeb.Haytni, config)
  end

  describe "Haytni.LockablePlugin.on_failed_authentication/5 (callback)" do
    setup do
      [
        config: Haytni.LockablePlugin.build_config(),
      ]
    end

    test "ensures failed_attempts is (only) incremented while it doesn't exceed maximum_attempts", %{config: config} do
      #user = %User{id: 0, locked_at: nil, failed_attempts: 0}
      user = user_fixture()
      updates = [inc: [failed_attempts: 1]]

      Range.new(0, config.maximum_attempts - 2)
      |> Enum.reduce(
        user,
        fn attempt, user ->
          assert user.failed_attempts == attempt

          {multi, changes} = on_failed_authentication(config, user)
          assert [{:increment_failed_attempts, {:update_all, query, ^updates, []}}] = Ecto.Multi.to_list(multi)
          assert [] == changes

          HaytniTest.Repo.update_all(query, updates)
          [updated_user] = HaytniTest.Repo.all(user.__struct__)
          assert updated_user.id == user.id
          assert updated_user.failed_attempts == user.failed_attempts + 1
          assert is_nil(updated_user.locked_at)
          assert [] == HaytniTest.Repo.all(Haytni.Token.tokens_from_user_query(user, Haytni.RememberablePlugin.token_context(nil)))

          updated_user
        end
      )
    end

    for strategy <- Haytni.LockablePlugin.Config.available_strategies() do
      test "ensures account becomes locked if failed_attempts >= maximum_attempts (strategy: #{strategy})", %{config: config} do
        config = %{config | unlock_strategy: unquote(strategy)}
        # NOTE: user needs an email for email based strategies
        user = %User{email: "test@notadomain.com", locked_at: nil, failed_attempts: 0}

        Range.new(config.maximum_attempts - 1, config.maximum_attempts + 1) # ensures locking takes place even if failed_attempts > maximum_attempts
        |> Enum.each(
          fn attempt ->
            {multi, changes} = on_failed_authentication(config, %{user | failed_attempts: attempt})
            changes_as_map = Enum.into(changes, %{})

            assert %{locked_at: at} = changes_as_map
            assert %DateTime{} = at
            if Haytni.LockablePlugin.email_strategy_enabled?(config) do
              assert [{:token, {:insert, %Ecto.Changeset{}, []}}, {:send_unlock_instructions, {:run, _function}}] = Ecto.Multi.to_list(multi)
            else
              assert [] == Ecto.Multi.to_list(multi)
            end
          end
        )
      end
    end

    for strategy <- Haytni.LockablePlugin.Config.email_strategies() do
      test "ensures an email was sent for strategy #{strategy} when lock happens", %{config: config} do
        config = %{config | unlock_strategy: unquote(strategy)}
        user = %User{email: "test@notadomain.com", failed_attempts: config.maximum_attempts}
        {multi, changes} = on_failed_authentication(config, user)

        updated_user =
          user
          |> Ecto.Changeset.change(changes)
          |> Ecto.Changeset.apply_changes()

        assert [{:token, {:insert, changeset = %Ecto.Changeset{}, []}}, {:send_unlock_instructions, {:run, fun}}] = Ecto.Multi.to_list(multi)
        assert {:ok, true} = fun.(HaytniTest.Repo, %{user: updated_user, token: changeset.data})
        assert_delivered_email Haytni.LockableEmail.unlock_instructions_email(updated_user, Haytni.Token.url_encode(changeset.data), HaytniTestWeb.Haytni, config)
      end
    end
  end
end
