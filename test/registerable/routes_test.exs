defmodule Haytni.Registerable.RoutesTest do
  use HaytniWeb.ConnCase, async: true

  defp expected_registerable_routes(prefix, new_prefix, edit_prefix) do
    [
      %{route: new_prefix, method: "GET", action: :new, controller: HaytniWeb.Registerable.RegistrationController},
      %{route: prefix, method: "POST", action: :create, controller: HaytniWeb.Registerable.RegistrationController},
      %{route: edit_prefix, method: "GET", action: :edit, controller: HaytniWeb.Registerable.RegistrationController},
      %{route: prefix, method: "PUT", action: :update, controller: HaytniWeb.Registerable.RegistrationController},
      %{route: prefix, method: "PATCH", action: :update, controller: HaytniWeb.Registerable.RegistrationController},
      #%{route: prefix, method: "DELETE", action: :delete, controller: HaytniWeb.Registerable.RegistrationController},
    ]
  end

  defp expected_registerable_routes(prefix) do
    expected_registerable_routes(prefix, prefix <> "/new", prefix <> "/edit")
  end

  describe "Haytni.RegisterablePlugin.routes/3 (callback)" do
    test "ensures unlock routes are part of the router" do
      expected_registerable_routes("/registration")
      |> check_routes(HaytniTestWeb.Router)
    end

    test "checks customized routes for registerable" do
      expected_registerable_routes("/CR/users", "/CR/register", "/CR/profile")
      |> check_routes(HaytniTestWeb.Router)
    end
  end
end
