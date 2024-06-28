defmodule Haytni.Rolable.RoleDeleteControllerTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.RolablePlugin,
  ]

  describe "HaytniWeb.Rolable.RoleController#delete" do
    test "raises if id doesn't exist", %{conn: conn} do
      assert_error_sent 404, fn ->
        delete(conn, Routes.haytni_user_role_path(conn, :delete, id()))
      end
    end

    test "checks successful registration", %{conn: conn} do
      role = role_fixture()
      assert [role] == @plugin.list_roles(@stack)

      conn
      |> delete(Routes.haytni_user_role_path(conn, :delete, role))
      |> redirected_to()
      |> (& assert &1 == Routes.haytni_user_role_path(conn, :index)).()

      assert [] == @plugin.list_roles(@stack)
    end
  end
end
