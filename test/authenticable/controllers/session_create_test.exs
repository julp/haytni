defmodule Haytni.Authenticable.SessionCreateControllerTest do
  use HaytniWeb.ConnCase, async: true

  describe "HaytniWeb.Authenticable.SessionController#create" do
    test "checks error on invalid credentials", %{conn: conn} do
      new_conn = post(conn, Routes.session_path(conn, :create), session_params_without_rememberme())
      assert contains_text?(html_response(new_conn, 200), Haytni.AuthenticablePlugin.invalid_credentials_message())
    end

    test "checks successful authentication (scope: user)", %{conn: conn} do
      user = user_fixture()
      new_conn = post(conn, Routes.session_path(conn, :create), session_params_without_rememberme(user))
      # TODO: bypass confirmable plugin and check for session + current_user in assign?
      assert contains_text?(html_response(new_conn, 200), Haytni.ConfirmablePlugin.pending_confirmation_message())
    end

    test "checks successful authentication (scope: admin)", %{conn: conn} do
      admin = admin_fixture()
      new_conn = conn
      |> Plug.Conn.put_private(:haytni, HaytniTestWeb.Haytni2)
      |> post(Routes.admin_session_path(conn, :create), session_params_without_rememberme(admin))
      assert new_conn.halted
      assert Phoenix.ConnTest.redirected_to(new_conn) == "/"
    end
  end
end
