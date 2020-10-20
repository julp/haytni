defmodule Haytni.Authenticable.FindUserTest do
  use HaytniWeb.ConnCase, async: true

  describe "Haytni.AuthenticablePlugin.find_user/3 (callback)" do
    setup %{conn: conn} do
      [
        config: Haytni.AuthenticablePlugin.build_config(),
        conn: Phoenix.ConnTest.init_test_session(conn, %{}),
      ]
    end

    test "a still valid user has his session restored", %{conn: conn, config: config} do
      user = user_fixture()

      {conn, found_user} =
        conn
        |> put_session(:user_id, user.id)
        |> Haytni.AuthenticablePlugin.find_user(HaytniTestWeb.Haytni, config)

      assert user.id == found_user.id

      conn
      |> get_session(:user_id)
      |> (& assert &1 == user.id).()
    end

    test "a now deleted user is automaticaly dropped (session is terminated)", %{conn: conn, config: config} do
      {conn, nil} =
        conn
        |> put_session(:user_id, 0)
        |> Haytni.AuthenticablePlugin.find_user(HaytniTestWeb.Haytni, config)

      conn
      |> get_session(:user_id)
      |> (& assert is_nil(&1)).()
    end
  end
end
