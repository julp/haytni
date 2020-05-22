defmodule Haytni.Authenticable.SessionCreateControllerTest do
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

  @spec assert_200_and_contains_message(conn :: Plug.Conn.t, message :: String.t) :: true | no_return
  defp assert_200_and_contains_message(conn, message) do
    assert conn
    |> html_response(200)
    |> contains_text?(message)
  end

  describe "HaytniWeb.Authenticable.SessionController#create" do
    setup do
      {:ok, user: user_fixture(), admin: admin_fixture()}
    end

    test "checks error on invalid credentials", %{conn: conn} do
      conn
      |> conn_to_user_session_path()
      |> assert_200_and_contains_message(Haytni.AuthenticablePlugin.invalid_credentials_message())
    end

    test "checks successful authentication (scope: user)", %{conn: conn, user: user, admin: admin} do
      conn
      |> conn_to_user_session_path(user)
      # TODO: bypass confirmable plugin and check for session + current_user in assign?
      |> assert_200_and_contains_message(Haytni.ConfirmablePlugin.pending_confirmation_message())

      conn
      |> conn_to_user_session_path(admin)
      |> assert_200_and_contains_message(Haytni.AuthenticablePlugin.invalid_credentials_message())
    end

    test "checks successful authentication (scope: admin)", %{conn: conn, user: user, admin: admin} do
      new_conn = conn
      |> conn_to_admin_session_path(admin)
      assert new_conn.halted
      assert Phoenix.ConnTest.redirected_to(new_conn) == "/"

      conn
      |> conn_to_admin_session_path()
      |> assert_200_and_contains_message(Haytni.AuthenticablePlugin.invalid_credentials_message())

      conn
      |> conn_to_admin_session_path(user)
      |> assert_200_and_contains_message(Haytni.AuthenticablePlugin.invalid_credentials_message())
    end
  end
end
