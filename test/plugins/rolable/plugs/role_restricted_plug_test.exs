defmodule Haytni.Rolable.RoleRestrictedPlugTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.RolablePlugin,
  ]

  @role_name "ADMIN"
  @spec do_call(conn :: Plug.Conn.t, current_user :: nil | struct, roles :: String.t | [String.t]) :: Plug.Conn.t
  defp do_call(conn, current_user, roles) do
    options = HaytniWeb.RolablePlugin.RoleRestrictedPlug.init(roles)

    conn
    |> init_test_session(%{})
    |> Plug.Conn.assign(:current_user, current_user)
#     |> fetch_session()
    |> fetch_flash()
    |> HaytniWeb.RolablePlugin.RoleRestrictedPlug.call(options)
  end

  describe "HaytniWeb.Rolable.RoleRestrictedPlugTest" do
    test "success: a user with the role get granted", %{conn: conn} do
      conn = do_call(conn, %HaytniTest.User{roles: [%HaytniTest.UserRole{name: "BAR"}, %HaytniTest.UserRole{name: @role_name}]}, @role_name)

      refute conn.halted
      assert is_nil(conn.status)
    end

    test "failure: an anonymous user get denied", %{conn: conn} do
      conn = do_call(conn, nil, @role_name)

      assert conn.halted
      assert redirected_to(conn, 302) == "/"
    end

    test "failure: a user without the role get denied", %{conn: conn} do
      conn = do_call(conn, %HaytniTest.User{roles: [%HaytniTest.UserRole{name: "FOO"}]}, @role_name)

      assert conn.halted
      assert redirected_to(conn, 302) == "/"
    end
  end
end
