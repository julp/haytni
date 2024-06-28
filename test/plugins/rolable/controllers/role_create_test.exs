defmodule Haytni.Rolable.RoleCreateControllerTest do
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

  describe "HaytniWeb.Rolable.RoleController#create" do
    test "failure: ensure we hit the creation form again on invalid data", %{conn: conn} do
      response =
        conn
        |> post(Routes.haytni_user_role_path(conn, :create), role_params())
        |> html_response(200)

      assert response =~ "<form "
      assert response =~ "action=\"#{Routes.haytni_user_role_path(conn, :create)}\""
      assert contains_text?(response, empty_message())
    end

    test "success: the role is inserted and we are redirect on the index", %{conn: conn} do
      name = "a very special role"
      assert [] == @plugin.list_roles(@stack)

      conn
      |> post(Routes.haytni_user_role_path(conn, :create), role_params(name: name))
      |> redirected_to()
      |> (& assert &1 == Routes.haytni_user_role_path(conn, :index)).()

      assert [%HaytniTest.UserRole{name: ^name}] = @plugin.list_roles(@stack)
    end
  end
end
