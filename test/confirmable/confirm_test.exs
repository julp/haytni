defmodule Haytni.Confirmable.ConfirmTest do
  use HaytniWeb.ConnCase, async: true

  alias HaytniTest.User

  describe "Haytni.ConfirmablePlugin.confirm/1" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "ensures account get confirmed from its associated confirmation_token", %{user: user = %HaytniTest.User{id: id}} do
      assert updated_user = %HaytniTest.User{id: ^id} = Haytni.ConfirmablePlugin.confirm(user.confirmation_token)

      assert is_binary(user.confirmation_token)
      assert nil == updated_user.confirmation_token

      assert nil == user.confirmed_at
      assert %DateTime{} = updated_user.confirmed_at
    end

    test "ensures an unexistant confirmation_token is rejected", %{user: _user = %HaytniTest.User{id: id}} do
      assert {:error, reason} = Haytni.ConfirmablePlugin.confirm("not a match")
      assert [found_user = %HaytniTest.User{id: ^id, confirmed_at: nil}] = Haytni.Users.list_users()
      assert is_binary(found_user.confirmation_token)
    end

    test "ensures an expired confirmation_token is rejected", %{user: user = %User{id: id}} do
      new_confirmation_sent_at = Haytni.ConfirmablePlugin.confirm_within()
      |> Haytni.duration()
      |> Kernel.+(1)
      |> seconds_ago()

      %User{id: ^id} = user
      |> Ecto.Changeset.change(confirmation_sent_at: new_confirmation_sent_at)
      |> Haytni.repo().update!()

      assert {:error, reason} = Haytni.ConfirmablePlugin.confirm(user.confirmation_token)
      assert reason =~ ~R/expired/i
    end
  end
end
