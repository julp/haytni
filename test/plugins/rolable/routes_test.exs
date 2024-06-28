defmodule Haytni.Rolable.RoutesTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.RolablePlugin,
  ]

  defp expected_rolable_routes(prefix) do
    [
      %{route: prefix, method: "GET", action: :index, controller: HaytniWeb.Rolable.RoleController},
      %{route: prefix <> "/new", method: "GET", action: :new, controller: HaytniWeb.Rolable.RoleController},
      %{route: prefix, method: "POST", action: :create, controller: HaytniWeb.Rolable.RoleController},
      %{route: prefix <> "/:id/edit", method: "GET", action: :edit, controller: HaytniWeb.Rolable.RoleController},
      %{route: prefix <> "/:id", method: "PATCH", action: :update, controller: HaytniWeb.Rolable.RoleController},
      %{route: prefix <> "/:id", method: "DELETE", action: :delete, controller: HaytniWeb.Rolable.RoleController},
    ]
  end

  describe "Haytni.RolablePlugin.routes/2" do
    test "ensures invitation routes are part of the router for scope = :user" do
      "/back/role"
      |> expected_rolable_routes()
      |> check_routes(@router)
    end
  end
end
