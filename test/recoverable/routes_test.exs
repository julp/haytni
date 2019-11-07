defmodule Haytni.Recoverable.RoutesTest do
  use HaytniWeb.ConnCase, async: true

  @routes [
    %{route: "/password/new", method: "GET", action: :new, controller: HaytniWeb.Recoverable.PasswordController},
    %{route: "/password", method: "POST", action: :create, controller: HaytniWeb.Recoverable.PasswordController},
    %{route: "/password/edit", method: "GET", action: :edit, controller: HaytniWeb.Recoverable.PasswordController},
    %{route: "/password", method: "PUT", action: :update, controller: HaytniWeb.Recoverable.PasswordController},
    %{route: "/password", method: "PATCH", action: :update, controller: HaytniWeb.Recoverable.PasswordController},
  ]

  describe "Haytni.RecoverablePlugin.routes/2 (callback)" do
    test "ensures password recovering routes are part of the router" do
      @routes
      |> Enum.each(
        fn %{route: route, method: method, action: action, controller: controller} ->
          assert %{route: ^route, plug: ^controller, plug_opts: ^action} = Phoenix.Router.route_info(HaytniTestWeb.Router, method, route, "test.com")
        end
      )
    end
  end
end
