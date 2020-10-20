defmodule Haytni.Authenticable.OnSuccessfulAuthenticationTest do
  use HaytniWeb.ConnCase, async: true

  setup %{conn: conn} do
    [
      config: Haytni.AuthenticablePlugin.build_config(),
      conn: Phoenix.ConnTest.init_test_session(conn, %{}),
    ]
  end

  describe "Haytni.AuthenticablePlugin.on_successful_authentication/6 (callback)" do
    test ":admin_id key is put in session for HaytniTestWeb.HaytniAdmin", %{conn: conn, config: config} do
      admin = %HaytniTest.Admin{id: 4648}
      {conn, _multi, []} = Haytni.AuthenticablePlugin.on_successful_authentication(conn, admin, Ecto.Multi.new(), Keyword.new(), HaytniTestWeb.HaytniAdmin, config)

      assert admin.id == Plug.Conn.get_session(conn, :admin_id)
    end

    test ":user_id key is put in session for HaytniTestWeb.Haytni", %{conn: conn, config: config} do
      user = %HaytniTest.User{id: 6465}
      {conn, _multi, []} = Haytni.AuthenticablePlugin.on_successful_authentication(conn, user, Ecto.Multi.new(), Keyword.new(), HaytniTestWeb.Haytni, config)

      assert user.id == Plug.Conn.get_session(conn, :user_id)
    end
  end
end
