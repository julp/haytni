defmodule Haytni.Lockable.RoutesTest do
  use HaytniWeb.ConnCase, async: true

  defp expected_lockable_routes(prefix) do
    [
      %{route: prefix, method: "GET", action: :show, controller: HaytniWeb.Lockable.UnlockController},
      %{route: prefix <> "/new", method: "GET", action: :new, controller: HaytniWeb.Lockable.UnlockController},
      %{route: prefix, method: "POST", action: :create, controller: HaytniWeb.Lockable.UnlockController},
    ]
  end

  describe "Haytni.LockablePlugin.routes/2 (callback)" do
    test "ensures unlock routes are part of the router" do
      "/unlock"
      |> expected_lockable_routes()
      |> check_routes(HaytniTestWeb.Router)
    end

    test "checks customized routes for lockable" do
      "/CR/unblock"
      |> expected_lockable_routes()
      |> check_routes(HaytniTestWeb.Router)
    end
  end
end
