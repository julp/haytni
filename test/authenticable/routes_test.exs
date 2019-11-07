defmodule Haytni.Authenticable.RoutesTest do
  use HaytniWeb.ConnCase, async: true

  @routes [
    %{route: "/session/new", method: "GET", action: :new, controller: HaytniWeb.Authenticable.SessionController},
    %{route: "/session", method: "POST", action: :create, controller: HaytniWeb.Authenticable.SessionController},
    %{route: "/session", method: "DELETE", action: :delete, controller: HaytniWeb.Authenticable.SessionController},
  ]

  describe "Haytni.AuthenticablePlugin.routes/2 (callback)" do
    test "ensures authenticable routes are part of the router" do
      @routes
      |> Enum.each(
        fn %{route: route, method: method, action: action, controller: controller} ->
          assert %{route: ^route, plug: ^controller, plug_opts: ^action} = Phoenix.Router.route_info(HaytniTestWeb.Router, method, route, "test.com")
        end
      )
    end
  end
end
