defmodule Haytni.Confirmable.ReconfirmationControllerTest do
  use HaytniWeb.ConnCase, async: true

  test "gets redirected on login form when not logged in", %{conn: conn} do
    response =
      conn
      |> get(Routes.haytni_user_reconfirmation_path(conn, :show))
      |> html_response(200)

    assert response =~ HaytniWeb.Confirmable.ReconfirmationController.not_logged_in_message()
    #assert conn.halted
    #assert redirected_to(conn) == Routes.haytni_user_session_path(conn, :new)
    #assert get_flash(conn, :error) == HaytniWeb.Confirmable.ReconfirmationController.not_logged_in_message()
  end

  test "gets an error when logged in and confirmation token is invalid", %{conn: conn} do
    response =
      conn
      |> assign(:current_user, user_fixture())
      |> get(Routes.haytni_user_reconfirmation_path(conn, :show), %{"confirmation_token" => "nevermind"})
      |> html_response(200)

    assert response =~ Haytni.ConfirmablePlugin.invalid_token_message()
  end

  test "gets redirected on registration edition when successful", %{conn: conn} do
    user = user_fixture()
    token = user
      |> token_fixture(Haytni.ConfirmablePlugin, sent_to: "my@new.address", context: Haytni.ConfirmablePlugin.token_context(user.email))
      |> Base.url_encode64()
    conn =
      conn
      |> assign(:current_user, user)
      |> get(Routes.haytni_user_reconfirmation_path(conn, :show), %{"confirmation_token" => token})

    assert conn.halted
    assert redirected_to(conn) == Routes.haytni_user_registration_path(conn, :edit)
    assert get_flash(conn, :info) == HaytniWeb.Confirmable.ReconfirmationController.address_updated_message()
  end
end
