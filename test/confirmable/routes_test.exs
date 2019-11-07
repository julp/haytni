defmodule Haytni.Confirmable.RoutesTest do
  use HaytniWeb.ConnCase, async: true

  @routes [
    %{route: "/confirmation", method: "GET", action: :show, controller: HaytniWeb.Confirmable.ConfirmationController},
    %{route: "/confirmation/new", method: "GET", action: :new, controller: HaytniWeb.Confirmable.ConfirmationController},
    %{route: "/confirmation", method: "POST", action: :create, controller: HaytniWeb.Confirmable.ConfirmationController},
  ]

  describe "Haytni.ConfirmablePlugin.routes/2 (callback)" do
    test "ensures confirmation routes are part of the router" do
      @routes
      |> Enum.each(
        fn %{route: route, method: method, action: action, controller: controller} ->
          assert %{route: ^route, plug: ^controller, plug_opts: ^action} = Phoenix.Router.route_info(HaytniTestWeb.Router, method, route, "test.com")
        end
      )
    end
  end
end
