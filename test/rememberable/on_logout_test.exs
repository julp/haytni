defmodule Haytni.Rememberable.OnLogoutTest do
  use HaytniWeb.ConnCase, async: true

  defp do_test(%{conn: conn, config: config}) do
    conn =
      conn
      |> Haytni.RememberablePlugin.add_rememberme_cookie("azerty", config)
      |> Haytni.RememberablePlugin.on_logout(config)

    assert_cookie_deletion(conn, config.remember_cookie_name)
  end

  describe "Haytni.RememberablePlugin.on_logout/2 (callback)" do
    setup do
      [
        config: Haytni.RememberablePlugin.build_config(),
      ]
    end

    test "ensures rememberme cookie is removed (asked for removal to the client) on logout", params do
      params
      |> do_test()
    end

    test "ensures rememberme cookie is removed (asked for removal to the client) on logout even if it was customized", params do
      params
      |> update_in(~W[config]a, &(%{&1 | remember_cookie_name: "JSESSIONID"}))
      |> do_test()
    end
  end
end
