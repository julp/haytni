defmodule Haytni.Confirmable.ConfirmationShowControllerTest do
  use HaytniWeb.ConnCase, async: true

  describe "HaytniWeb.Confirmable.ConfirmationController#show" do
    test "checks error on invalid token", %{conn: conn} do
      response =
        conn
        |> get(Routes.haytni_user_confirmation_path(conn, :show), %{"confirmation_token" => "not a match"})
        |> html_response(200)

      assert contains_text?(response, Haytni.ConfirmablePlugin.invalid_token_message())
    end

    test "checks successful confirmation", %{conn: conn} do
      user =
        Haytni.ConfirmablePlugin.build_config()
        |> Haytni.ConfirmablePlugin.new_confirmation_attributes()
        |> user_fixture()

      response =
        conn
        |> get(Routes.haytni_user_confirmation_path(conn, :show), %{"confirmation_token" => user.confirmation_token})
        |> html_response(200)

      assert contains_text?(response, HaytniWeb.Confirmable.ConfirmationController.confirmed_message())
    end
  end
end
