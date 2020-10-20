defmodule Haytni.Authenticable.OnLogoutTest do
  use HaytniWeb.ConnCase, async: true

  setup %{conn: conn} do
    user = %HaytniTest.User{id: 6465}
    admin = %HaytniTest.Admin{id: 4648}
    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{user_id: user.id, admin_id: admin.id})
      |> assign(:current_user, user)
      |> assign(:current_admin, admin)

    [
      conn: conn,
      config: Haytni.AuthenticablePlugin.build_config(),
    ]
  end

  describe "Haytni.AuthenticablePlugin.on_logout/3 (callback)" do
    if false do
      test "whole session is destroyed with scope: :all", %{conn: conn, config: config} do
        conn
        |> Haytni.AuthenticablePlugin.on_logout(HaytniTestWeb.Haytni, config, scope: :all)
        |> Plug.Conn.get_session()
        |> (& assert &1 == %{}).()
      end
    end

    test "only :admin_id key is deleted for HaytniTestWeb.HaytniAdmin", %{conn: conn, config: config} do
      conn = Haytni.AuthenticablePlugin.on_logout(conn, HaytniTestWeb.HaytniAdmin, config)
      refute Plug.Conn.get_session(conn, :admin_id)
      assert Plug.Conn.get_session(conn, :user_id)
    end

    test "only :user_id key is deleted for HaytniTestWeb.Haytni", %{conn: conn, config: config} do
      conn = Haytni.AuthenticablePlugin.on_logout(conn, HaytniTestWeb.Haytni, config)
      refute Plug.Conn.get_session(conn, :user_id)
      assert Plug.Conn.get_session(conn, :admin_id)
    end
  end
end
