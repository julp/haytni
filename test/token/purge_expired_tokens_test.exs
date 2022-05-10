defmodule Haytni.Token.PurgeExpiredTokensTest do
  use HaytniWeb.ConnCase, async: true

  describe "Haytni.Token.purge_expired_tokens/1" do
    setup do
      [
        user: user_fixture(),
        plugin: Haytni.ConfirmablePlugin,
        config: Haytni.ConfirmablePlugin.build_config(),
      ]
    end

    @spec do_test(user :: HaytniTest.User.t) :: [Ecto.Schema.t]
    defp do_test(user = %HaytniTest.User{}) do
      _ = Haytni.Token.purge_expired_tokens(HaytniTestWeb.Haytni)

      user
      |> Haytni.Token.tokens_from_user_query(:all)
      |> HaytniTest.Repo.all()
    end

    test "valid (non expired) tokens are kept", %{user: user, plugin: plugin, config: config} do
      token =
        user
        |> token_fixture(plugin, inserted_at: config.confirm_within - 1)

      [^token] = do_test(user)
    end

    test "expired tokens are deleted", %{user: user, plugin: plugin, config: config} do
      user
      |> token_fixture(plugin, inserted_at: config.confirm_within + 1)

      [] = do_test(user)
    end

    test "invalid tokens (likely a plugin now disabled) are deleted", %{user: user} do
      user
      |> token_fixture(nil, context: "invalid/nonexistent")

      [] = do_test(user)
    end
  end
end
