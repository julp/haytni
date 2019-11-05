defmodule Haytni.Lockable.OnFailedAuthentificationTest do
  use HaytniWeb.ConnCase, async: true
  use Bamboo.Test

  alias HaytniTest.User

  describe "Haytni.LockablePlugin.on_failed_authentification/2 (callback)" do
    setup do
      {:ok, max: Haytni.LockablePlugin.maximum_attempts()}
    end

    test "ensures failed_attempts is (only) incremented while it doesn't exceed maximum_attempts", %{max: max} do
      user = %User{locked_at: nil, unlock_token: nil, failed_attempts: 0}

      Range.new(0, max - 2)
      |> Enum.each(
        fn attempt ->
          assert [failed_attempts: attempt + 1] == Haytni.LockablePlugin.on_failed_authentification(%{user | failed_attempts: attempt}, Keyword.new())
        end
      )
    end

    @strategies ~W[both]a
    #@strategies ~W[none email time both]a # TODO: handle strategy
    @email_strategies ~W[both email]a

    for strategy <- @strategies do
      test "ensures account becomes locked if failed_attempts >= maximum_attempts (strategy: #{strategy})", %{max: max} do
        # NOTE: user needs an email for email based strategies
        user = %User{email: "test@notadomain.com", locked_at: nil, unlock_token: nil, failed_attempts: 0}

        Range.new(max - 1, max + 1) # ensures locking takes place even if failed_attempts > maximum_attempts
        |> Enum.each(
          fn attempt ->
            result_as_map = Haytni.LockablePlugin.on_failed_authentification(%{user | failed_attempts: attempt}, Keyword.new())
            |> Enum.into(%{})

            assert %{locked_at: at, unlock_token: token} = result_as_map

            refute is_nil(at)
            assert is_binary(token)
          end
        )
      end
    end

    for strategy <- @email_strategies do
      test "ensures an email was sent for strategy #{strategy} when lock happens", %{max: max} do
        user = %User{email: "test@notadomain.com", failed_attempts: max}
        changes = Haytni.LockablePlugin.on_failed_authentification(user, Keyword.new())

        updated_user = user
        |> Ecto.Changeset.change(changes)
        |> Ecto.Changeset.apply_changes()

        assert_delivered_email Haytni.LockableEmail.unlock_instructions_email(updated_user)
      end
    end
  end
end
