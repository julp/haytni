defmodule Haytni.LiveView.OnLogoutTest do
  use HaytniWeb.ConnCase, async: true

  defp socket_id(_module, user) do
    "socket:#{user.id}"
  end

  describe "Haytni.LiveViewPlugin.on_logout/3 (callback)" do
    setup do
      [
        module: HaytniTestWeb.Haytni,
        config: Haytni.LiveViewPlugin.build_config(socket_id: &socket_id/2),
      ]
    end

    test "ensures a disconnect message is broadcasted at logout", %{conn: conn, module: module, config: config} do
      user = %HaytniTest.User{id: 98475}
      socket_id = config.socket_id.(module, user)
      HaytniTestWeb.Endpoint.subscribe(socket_id)

      _conn =
        conn
        |> Plug.Conn.assign(:current_user, user)
        |> Haytni.LiveViewPlugin.on_logout(module, config)

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^socket_id,
        event: "disconnect",
      }
    end
  end
end
