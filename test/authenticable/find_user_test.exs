defmodule Haytni.Authenticable.FindUserTest do
  use HaytniWeb.ConnCase, async: true

  @session_key :user_token
  describe "Haytni.AuthenticablePlugin.find_user/3 (callback)" do
    setup %{conn: conn} do
      [
        user: user_fixture(),
        config: Haytni.AuthenticablePlugin.build_config(),
        conn: Phoenix.ConnTest.init_test_session(conn, %{}),
      ]
    end

    test "a still valid user has his session restored", %{conn: conn, config: config, user: user} do
      token =
        user
        |> token_fixture(Haytni.AuthenticablePlugin)
        |> Haytni.Token.url_encode()

      {conn, found_user} =
        conn
        |> put_session(@session_key, token)
        |> Haytni.AuthenticablePlugin.find_user(HaytniTestWeb.Haytni, config)

      assert user.id == found_user.id

      conn
      |> get_session(@session_key)
      |> (& assert is_binary(&1)).()
    end

    test "an expired session is automaticaly dropped (session is terminated)", %{conn: conn, config: config, user: user} do
      token =
        user
        |> token_fixture(Haytni.AuthenticablePlugin, inserted_at: config.session_maxlifetime + 1)
        |> Haytni.Token.url_encode()

      {conn, nil} =
        conn
        |> put_session(@session_key, token)
        |> Haytni.AuthenticablePlugin.find_user(HaytniTestWeb.Haytni, config)

      conn
      |> get_session(@session_key)
      |> (& assert is_nil(&1)).()
    end

    test "a now deleted user is automaticaly dropped (session is terminated)", %{conn: conn, config: config} do
      {conn, nil} =
        conn
        |> put_session(@session_key, "")
        |> Haytni.AuthenticablePlugin.find_user(HaytniTestWeb.Haytni, config)

      conn
      |> get_session(@session_key)
      |> (& assert is_nil(&1)).()
    end
  end
end
