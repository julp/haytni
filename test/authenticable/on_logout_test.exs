defmodule Haytni.Authenticable.OnLogoutTest do
  use HaytniWeb.ConnCase, async: true

  setup %{conn: conn} do
    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{user_token: "b6yoC3rFoDYA", admin_token: "zys5bcumWf5J"})

    [
      conn: conn,
      config: Haytni.AuthenticablePlugin.build_config(),
    ]
  end

  describe "Haytni.AuthenticablePlugin.on_logout/3 (callback)" do
    if false do
      test "whole session is destroyed with scope: :all", %{conn: conn} do
        conn
        |> Haytni.AuthenticablePlugin.on_logout(HaytniTestWeb.Haytni, config, scope: :all)
        |> Plug.Conn.get_session()
        |> (& assert &1 == %{}).()
      end
    end

    test "only :admin_token key is deleted for HaytniTestWeb.HaytniAdmin", %{conn: conn, config: config} do
      conn = Haytni.AuthenticablePlugin.on_logout(conn, HaytniTestWeb.HaytniAdmin, config)
      refute Plug.Conn.get_session(conn, :admin_token)
      assert Plug.Conn.get_session(conn, :user_token)
    end

    test "only :user_token key is deleted for HaytniTestWeb.Haytni", %{conn: conn, config: config} do
      conn = Haytni.AuthenticablePlugin.on_logout(conn, HaytniTestWeb.Haytni, config)
      refute Plug.Conn.get_session(conn, :user_token)
      assert Plug.Conn.get_session(conn, :admin_token)
    end
  end
end
