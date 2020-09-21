defmodule Haytni.Rememberable.FindUserTest do
  use HaytniWeb.ConnCase, async: true

  describe "Haytni.RememberablePlugin.find_user/3 (callback)" do
    setup do
      user = user_fixture(remember_token: "hjzOqslZZu8M", remember_created_at: Haytni.Helpers.now())

      [
        user: user,
        config: Haytni.RememberablePlugin.build_config(),
      ]
    end

    test "gets nothing ({conn, nil}) if no token is present", %{conn: conn, config: config} do
      assert {%Plug.Conn{}, nil} = Haytni.RememberablePlugin.find_user(conn, HaytniTestWeb.Haytni, config)
    end

    if false do
      test "gets nothing ({conn, nil}) and rememberme cookie is deleted if token is expired", %{conn: conn, config: config} do
        user = user_fixture(remember_token: "mwMbedOBiqYT", remember_created_at: seconds_ago(config.remember_for + 1))
        result =
          conn
          |> add_rememberme_cookie(user.remember_token, config)
          |> Haytni.RememberablePlugin.find_user(HaytniTestWeb.Haytni, config)

        # NOTE/TODO: it won't work because RememberablePlugin doesn't check the value of the column remember_created_at,
        # it counts on Phoenix.Token.verify for expiration but we have no way to override time generation of the token
        # when calling Phoenix.Token.sign
        assert {new_conn = %Plug.Conn{}, nil} = result
        assert_cookie_deletion(new_conn, config.remember_cookie_name)
      end
    end

    test "gets nothing ({conn, nil}) and rememberme cookie is deleted if token doesn't match any user", %{conn: conn, config: config} do
      result =
        conn
        |> add_rememberme_cookie("not a match", config)
        |> Haytni.RememberablePlugin.find_user(HaytniTestWeb.Haytni, config)

      assert {new_conn = %Plug.Conn{}, nil} = result
      assert_cookie_deletion(new_conn, config.remember_cookie_name)
    end

    test "gets user ({conn, user}) if token is valid (and rememberme cookie is kept)", %{conn: conn, config: config, user: user} do
      result =
        conn
        |> add_rememberme_cookie(user.remember_token, config)
        |> Haytni.RememberablePlugin.find_user(HaytniTestWeb.Haytni, config)

      assert {new_conn = %Plug.Conn{}, found_user} = result
      assert found_user.id == user.id
      # NOTE: if the authentication by the rememberable cookie is successful, we don't emit any *rememberme*
      # cookie: the client keeps the one it has.
      refute_cookie_presence(new_conn, config.remember_cookie_name)
    end
  end
end
