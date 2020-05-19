defmodule Haytni.Confirmable.RoutesTest do
  use HaytniWeb.ConnCase, async: true

  defp expected_confirmation_routes(prefix) do
    [
      %{route: prefix, method: "GET", action: :show, controller: HaytniWeb.Confirmable.ConfirmationController},
      %{route: prefix <> "/new", method: "GET", action: :new, controller: HaytniWeb.Confirmable.ConfirmationController},
      %{route: prefix, method: "POST", action: :create, controller: HaytniWeb.Confirmable.ConfirmationController},
    ]
  end

  describe "Haytni.ConfirmablePlugin.routes/2 (callback)" do
    test "ensures confirmation routes are part of the router" do
      "/confirmation"
      |> expected_confirmation_routes()
      |> check_routes(HaytniTestWeb.Router)
    end

    test "checks customized routes for confirmable" do
      "/CR/check"
      |> expected_confirmation_routes()
      |> check_routes(HaytniTestWeb.Router)
    end
  end
end
