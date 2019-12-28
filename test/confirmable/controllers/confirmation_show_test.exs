defmodule Haytni.Confirmable.ConfirmationShowControllerTest do
  use HaytniWeb.ConnCase, async: true

  describe "HaytniWeb.Confirmable.ConfirmationController#show" do
    test "checks error on invalid token", %{conn: conn} do
      new_conn = get(conn, Routes.confirmation_path(conn, :show), %{"confirmation_token" => "not a match"})
      assert contains_text?(html_response(new_conn, 200), Haytni.ConfirmablePlugin.invalid_token_message())
    end

    test "checks successful confirmation", %{conn: conn} do
      user = Haytni.ConfirmablePlugin.build_config()
      |> Haytni.ConfirmablePlugin.new_confirmation_attributes()
      |> user_fixture()

      new_conn = get(conn, Routes.confirmation_path(conn, :show), %{"confirmation_token" => user.confirmation_token})
      assert contains_text?(html_response(new_conn, 200), HaytniWeb.Confirmable.ConfirmationController.confirmed_message())
    end
  end
end
