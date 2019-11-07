defmodule Haytni.Registerable.RoutesTest do
  use HaytniWeb.ConnCase, async: true

  @routes [
    %{route: "/registration/new", method: "GET", action: :new, controller: HaytniWeb.Registerable.RegistrationController},
    %{route: "/registration", method: "POST", action: :create, controller: HaytniWeb.Registerable.RegistrationController},
    %{route: "/registration/edit", method: "GET", action: :edit, controller: HaytniWeb.Registerable.RegistrationController},
    %{route: "/registration", method: "PUT", action: :update, controller: HaytniWeb.Registerable.RegistrationController},
    %{route: "/registration", method: "PATCH", action: :update, controller: HaytniWeb.Registerable.RegistrationController},
  ]

  describe "Haytni.RegisterablePlugin.routes/2 (callback)" do
    test "ensures unlock routes are part of the router" do
      @routes
      |> Enum.each(
        fn %{route: route, method: method, action: action, controller: controller} ->
          assert %{route: ^route, plug: ^controller, plug_opts: ^action} = Phoenix.Router.route_info(HaytniTestWeb.Router, method, route, "test.com")
        end
      )
    end
  end
end
