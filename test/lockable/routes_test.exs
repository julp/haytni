defmodule Haytni.Lockable.RoutesTest do
  use HaytniWeb.ConnCase, async: true

  @routes [
    %{route: "/unlock", method: "GET", action: :show, controller: HaytniWeb.Lockable.UnlockController},
    %{route: "/unlock/new", method: "GET", action: :new, controller: HaytniWeb.Lockable.UnlockController},
    %{route: "/unlock", method: "POST", action: :create, controller: HaytniWeb.Lockable.UnlockController},
  ]

  describe "Haytni.LockablePlugin.routes/2 (callback)" do
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
