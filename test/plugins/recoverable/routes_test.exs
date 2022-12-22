defmodule Haytni.Recoverable.RoutesTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.RecoverablePlugin,
  ]

  defp expected_recoverable_routes(prefix) do
    [
      %{route: prefix <> "/new", method: "GET", action: :new, controller: HaytniWeb.Recoverable.PasswordController},
      %{route: prefix, method: "POST", action: :create, controller: HaytniWeb.Recoverable.PasswordController},
      %{route: prefix <> "/edit", method: "GET", action: :edit, controller: HaytniWeb.Recoverable.PasswordController},
      %{route: prefix, method: "PUT", action: :update, controller: HaytniWeb.Recoverable.PasswordController},
      %{route: prefix, method: "PATCH", action: :update, controller: HaytniWeb.Recoverable.PasswordController},
    ]
  end

  describe "Haytni.RecoverablePlugin.routes/3 (callback)" do
    test "ensures password recovering routes are part of the router" do
      "/password"
      |> expected_recoverable_routes()
      |> check_routes(@router)
    end

    test "checks customized routes for recoverable" do
      "/CR/secret"
      |> expected_recoverable_routes()
      |> check_routes(@router)
    end
  end
end
