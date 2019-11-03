defmodule Haytni.Confirmable.ConfirmTest do
  use HaytniWeb.ConnCase, async: true

  describe "Haytni.ConfirmablePlugin.confirm/1" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "ensures account get confirmed from its associated confirmation_token", %{user: user = %HaytniTest.User{id: id}} do
      assert updated_user = %HaytniTest.User{id: ^id} = Haytni.ConfirmablePlugin.confirm(user.confirmation_token)

      assert is_binary(user.confirmation_token)
      assert nil == updated_user.confirmation_token

      assert nil == user.confirmed_at
      assert nil != updated_user.confirmed_at
    end

    test "ensures an unexistant confirmation_token is rejected", %{user: user = %HaytniTest.User{id: id}} do
      assert {:error, reason} = Haytni.ConfirmablePlugin.confirm("not a match")
      assert [found_user = %HaytniTest.User{id: ^id, confirmed_at: nil}] = Haytni.Users.list_users()
      assert is_binary(found_user.confirmation_token)
    end

    test "ensures an expired confirmation_token is rejected", %{user: user} do
      # TODO
    end
  end
end
