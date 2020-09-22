defmodule Haytni.Authenticable.SessionControllerTest do
  use HaytniWeb.ConnCase, async: true

  @spec conn_to_user_session_path(conn :: Plug.Conn.t, user :: map | struct) :: Plug.Conn.t
  defp conn_to_user_session_path(conn, user \\ %{}) do
    post(conn, Routes.haytni_user_session_path(conn, :create), session_params_without_rememberme(user))
  end

  @spec conn_to_admin_session_path(conn :: Plug.Conn.t, user :: map | struct) :: Plug.Conn.t
  defp conn_to_admin_session_path(conn, user \\ %{}) do
    conn
    |> Plug.Conn.put_private(:haytni, HaytniTestWeb.Haytni2)
    |> post(Routes.admin_haytni_admin_session_path(conn, :create), session_params_without_rememberme(user))
  end

  @spec check_for_new_form(response :: String.t) :: true | no_return
  defp check_for_new_form(response) do
    assert response =~ "name=\"session[email]\""
    assert response =~ "name=\"session[password]\""
  end

  describe "HaytniWeb.Authenticable.SessionController#new" do
    test "renders form for authentication", %{conn: conn} do
      conn
      |> get(Routes.haytni_user_session_path(conn, :new))
      |> html_response(200)
      |> check_for_new_form()
    end
  end

  describe "HaytniWeb.Authenticable.SessionController#delete" do
    test "we get logged out (redirected + session deleted)", %{conn: conn} do
      conn =
        conn
        #|> Plug.Test.init_test_session(%{user_id: 6498})
        #|> Plug.Conn.put_private(:plug_skip_csrf_protection, true)
        |> delete(Routes.haytni_user_session_path(conn, :delete))

      assert conn.halted
      assert Phoenix.ConnTest.redirected_to(conn) == "/"
      refute Plug.Conn.get_session(conn, :user_id)
    end
  end

  describe "HaytniWeb.Authenticable.SessionController#create" do
    setup do
      [
        user: user_fixture(),
        admin: admin_fixture(),
      ]
    end

    test "checks error on invalid credentials", %{conn: conn} do
      response =
        conn
        |> conn_to_user_session_path()
        |> html_response(200)

      check_for_new_form(response)
      assert contains_text?(response, Haytni.AuthenticablePlugin.invalid_credentials_message())
    end

    test "checks successful authentication (scope: user)", %{conn: conn, user: user, admin: admin} do
      response =
        conn
        |> conn_to_user_session_path(user)
        |> html_response(200)

      # TODO: bypass confirmable plugin and check for session + current_user in assign?
      assert contains_text?(response, Haytni.ConfirmablePlugin.pending_confirmation_message())

      response =
        conn
        |> conn_to_user_session_path(admin)
        |> html_response(200)

      check_for_new_form(response)
      assert contains_text?(response, Haytni.AuthenticablePlugin.invalid_credentials_message())
    end

    test "checks successful authentication (scope: admin)", %{conn: conn, user: user, admin: admin} do
      new_conn = conn_to_admin_session_path(conn, admin)
      assert new_conn.halted
      assert Phoenix.ConnTest.redirected_to(new_conn) == "/"

      conn
      |> conn_to_admin_session_path()
      |> html_response(200)
      |> (& assert contains_text?(&1, Haytni.AuthenticablePlugin.invalid_credentials_message())).()

      conn
      |> conn_to_admin_session_path(user)
      |> html_response(200)
      |> (& assert contains_text?(&1, Haytni.AuthenticablePlugin.invalid_credentials_message())).()
    end
  end
end
