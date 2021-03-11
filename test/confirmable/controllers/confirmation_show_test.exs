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
      user = user_fixture()
      confirmation_token =
        user
        |> token_fixture(Haytni.ConfirmablePlugin, token: "7kB0dqV657")
        |> Haytni.Token.url_encode()

      response =
        conn
        |> get(Routes.haytni_user_confirmation_path(conn, :show), %{"confirmation_token" => confirmation_token})
        |> html_response(200)

      assert contains_text?(response, HaytniWeb.Confirmable.ConfirmationController.confirmed_message())
    end
  end
end
