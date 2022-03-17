defmodule Haytni.OnMountTest do
  use Haytni.DataCase, async: true

  setup do
    valid_user = user_fixture(confirmed_at: Haytni.Helpers.now())
    invalid_user = user_fixture(confirmed_at: nil)

    [
      valid_user: valid_user,
      invalid_user: invalid_user,
      module: HaytniTestWeb.Haytni,
      socket: %Phoenix.LiveView.Socket{},
    ]
  end

  defp to_session(nil), do: %{}
  # NOTE: keys for Live View session are strings, not atoms
  defp to_session(user = %_{}), do: %{"user_id" => user.id}

  describe "Haytni.on_mount/4" do
    test "without user", %{module: module, socket: socket} do
      {:cont, socket} = module.on_mount(:default, %{}, to_session(nil), socket)

      assert is_nil(socket.assigns.current_user)
    end

    test "with a valid user", %{module: module, socket: socket, valid_user: user} do
      {:cont, socket} = module.on_mount(:default, %{}, to_session(user), socket)

      assert socket.assigns.current_user.id == user.id
    end

    test "with an invalid user", %{module: module, socket: socket, invalid_user: user} do
      {:cont, socket} = module.on_mount(:default, %{}, to_session(user), socket)

      assert is_nil(socket.assigns.current_user)
    end
  end
end
