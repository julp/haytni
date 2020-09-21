defmodule Haytni.LogoutTest do
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
    ]
  end

  describe "Haytni.logout/3" do
    test "whole session is destroyed with scope: :all", %{conn: conn} do
      conn
      |> Haytni.logout(HaytniTestWeb.Haytni, scope: :all)
      |> Plug.Conn.get_session()
      |> (& assert &1 == %{}).()
    end

    test "only :admin_id key is deleted for HaytniTestWeb.HaytniAdmin", %{conn: conn} do
      conn = Haytni.logout(conn, HaytniTestWeb.HaytniAdmin)
      refute Plug.Conn.get_session(conn, :admin_id)
      assert Plug.Conn.get_session(conn, :user_id)
    end

    test "only :user_id key is deleted for HaytniTestWeb.Haytni", %{conn: conn} do
      conn = Haytni.logout(conn, HaytniTestWeb.Haytni)
      refute Plug.Conn.get_session(conn, :user_id)
      assert Plug.Conn.get_session(conn, :admin_id)
    end
  end
end
