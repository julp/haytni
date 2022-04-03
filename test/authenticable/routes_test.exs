defmodule Haytni.Authenticable.RoutesTest do
  use HaytniWeb.ConnCase, async: true

  defp expected_authenticable_routes(login_prefix, logout_prefix, logout_method) do
    [
      %{route: login_prefix <> (if login_prefix == logout_prefix, do: "/new", else: ""), method: "GET", action: :new, controller: HaytniWeb.Authenticable.SessionController},
      %{route: login_prefix, method: "POST", action: :create, controller: HaytniWeb.Authenticable.SessionController},
      %{route: logout_prefix, method: logout_method, action: :delete, controller: HaytniWeb.Authenticable.SessionController},
    ]
  end

  describe "Haytni.AuthenticablePlugin.routes/3 (callback)" do
    test "ensures authenticable routes are part of the router" do
      expected_authenticable_routes("/session", "/session", "DELETE")
      |> check_routes(HaytniTestWeb.Router)

      expected_authenticable_routes("/admin/session", "/admin/session", "DELETE")
      |> check_routes(HaytniTestWeb.Router)
    end

    test "checks customized routes for authenticable" do
      expected_authenticable_routes("/CR/login", "/CR/logout", "GET")
      |> check_routes(HaytniTestWeb.Router)
    end
  end
end
