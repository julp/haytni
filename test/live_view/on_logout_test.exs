defmodule Haytni.LiveView.OnLogoutTest do
  use HaytniWeb.ConnCase, async: true

  describe "Haytni.LiveViewPlugin.on_logout/2 (callback)" do
    setup do
      [
        config: Haytni.LiveViewPlugin.build_config(),
      ]
    end

    test "ensures a disconnect message is broadcasted at logout", %{conn: conn, config: config} do
      user = %HaytniTest.User{id: 98475}
      socket_id = config.socket_id.(user)
      HaytniTestWeb.Endpoint.subscribe(socket_id)

      _conn =
        conn
        |> Plug.Conn.assign(:current_user, user)
        |> Haytni.LiveViewPlugin.on_logout(HaytniTestWeb.Haytni, config)

      assert_receive %Phoenix.Socket.Broadcast{
        topic: socked_id,
        event: "disconnect",
      }
    end
  end
end
