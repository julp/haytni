defmodule Haytni.Confirmable.ConfirmTest do
  use Haytni.DataCase, async: true

  alias HaytniTest.User

  describe "Haytni.ConfirmablePlugin.confirm/3" do
    setup do
      config = Haytni.ConfirmablePlugin.build_config()
      user = config
      |> Haytni.ConfirmablePlugin.new_confirmation_attributes()
      |> user_fixture()

      {:ok, config: config, user: user}
    end

    test "ensures account get confirmed from its associated confirmation_token", %{config: config, user: user} do
      assert {:ok, updated_user} = Haytni.ConfirmablePlugin.confirm(HaytniTestWeb.Haytni, config, user.confirmation_token)
      assert updated_user.id == user.id

      assert is_binary(user.confirmation_token)
      assert is_nil(updated_user.confirmation_token)

      assert is_nil(user.confirmed_at)
      assert %DateTime{} = updated_user.confirmed_at
    end

    test "ensures an unexistant confirmation_token is rejected", %{config: config, user: _user = %HaytniTest.User{id: id}} do
      assert {:error, _reason} = Haytni.ConfirmablePlugin.confirm(HaytniTestWeb.Haytni, config, "not a match")
      assert [found_user = %HaytniTest.User{id: ^id, confirmed_at: nil}] = HaytniTest.Users.list_users()
      assert is_binary(found_user.confirmation_token)
    end

    test "ensures an expired confirmation_token is rejected", %{config: config, user: user = %User{id: id}} do
      new_confirmation_sent_at = config.confirm_within
      |> Kernel.+(1)
      |> seconds_ago()

      %User{id: ^id} = user
      |> Ecto.Changeset.change(confirmation_sent_at: new_confirmation_sent_at)
      |> HaytniTest.Repo.update!()

      assert {:error, Haytni.ConfirmablePlugin.expired_token_message()} == Haytni.ConfirmablePlugin.confirm(HaytniTestWeb.Haytni, config, user.confirmation_token)
    end
  end
end
