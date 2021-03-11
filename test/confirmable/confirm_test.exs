defmodule Haytni.Confirmable.ConfirmTest do
  use Haytni.DataCase, async: true

  describe "Haytni.ConfirmablePlugin.confirm/3" do
    setup do
      [
        user: user_fixture(),
        plugin: Haytni.ConfirmablePlugin,
        config: Haytni.ConfirmablePlugin.build_config(),
      ]
    end

    test "ensures account get confirmed from its associated confirmation_token", %{config: config, user: user} do
      confirmation_token =
        user
        |> token_fixture(Haytni.ConfirmablePlugin, token: "baL4R2KoOm", inserted_at: config.confirm_within - 1)
        |> Haytni.Token.url_encode()

      assert {:ok, updated_user} = Haytni.ConfirmablePlugin.confirm(HaytniTestWeb.Haytni, config, confirmation_token)
      assert updated_user.id == user.id

      assert is_nil(user.confirmed_at)
      assert %DateTime{} = updated_user.confirmed_at
    end

    test "ensures an unexistant confirmation_token is rejected", %{config: config, user: _user = %HaytniTest.User{id: id}} do
      assert {:error, _reason} = Haytni.ConfirmablePlugin.confirm(HaytniTestWeb.Haytni, config, "not a match")
      assert [found_user = %HaytniTest.User{id: ^id, confirmed_at: nil}] = HaytniTest.Users.list_users()
      assert is_nil(found_user.confirmed_at)
    end

    test "ensures an expired confirmation_token is rejected", %{config: config, user: user} do
      confirmation_token =
        user
        |> token_fixture(Haytni.ConfirmablePlugin, inserted_at: config.confirm_within + 1)
        |> Haytni.Token.url_encode()

      assert {:error, Haytni.ConfirmablePlugin.invalid_token_message()} == Haytni.ConfirmablePlugin.confirm(HaytniTestWeb.Haytni, config, confirmation_token)
    end
  end
end
