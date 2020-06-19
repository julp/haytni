defmodule Haytni.Invitable.RoutesTest do
  use HaytniWeb.ConnCase, async: true

  defp expected_invitable_routes(prefix) do
    [
      %{route: prefix <> "/new", method: "GET", action: :new, controller: HaytniWeb.Invitable.InvitationController},
      %{route: prefix, method: "POST", action: :create, controller: HaytniWeb.Invitable.InvitationController},
    ]
  end

  describe "Haytni.LockablePlugin.routes/2 (callback)" do
    test "ensures invitation routes are part of the router for scope = :user" do
      "/invitations"
      |> expected_invitable_routes()
      |> check_routes(HaytniTestWeb.Router)
    end
  end
end
