defmodule Haytni.Rolable.RoleUpdateControllerTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.RolablePlugin,
  ]

  defp role_params(attrs \\ %{}) do
    [
      name: "",
    ]
    |> Params.create(attrs)
    |> Params.wrap(:role)
  end

  describe "HaytniWeb.Rolable.RoleController#update" do
    setup do
      role = role_fixture()

      binding()
    end

    test "failure: raises on inexistent role", %{conn: conn} do
      assert_error_sent 404, fn ->
        delete(conn, Routes.haytni_user_role_path(conn, :update, id()))
      end
    end

    test "failure: ensure we hit the creation form again on invalid data", %{conn: conn, role: role} do
      response =
        conn
        |> patch(Routes.haytni_user_role_path(conn, :update, role), role_params())
        |> html_response(200)

      assert response =~ "<form "
      assert response =~ "action=\"#{Routes.haytni_user_role_path(conn, :update, role)}\""
      assert contains_text?(response, empty_message())
    end

    test "success: the role is updated and we are redirect on the index", %{conn: conn, role: role} do
      name = "the new role name"

      conn
      |> patch(Routes.haytni_user_role_path(conn, :update, role), role_params(name: name))
      |> redirected_to()
      |> (& assert &1 == Routes.haytni_user_role_path(conn, :index)).()

      [updated_role] = @plugin.list_roles(@stack)

      assert updated_role.id == role.id
      assert updated_role.name == name
    end
  end
end
