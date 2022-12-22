defmodule Haytni.Rememberable.OnLogoutTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.RememberablePlugin,
  ]

  defp do_test(%{conn: conn, config: config}) do
    conn =
      conn
      |> @plugin.add_rememberme_cookie("azerty", config)
      |> @plugin.on_logout(@stack, config)

    assert_cookie_deletion(conn, config.remember_cookie_name)
  end

  describe "Haytni.RememberablePlugin.on_logout/3 (callback)" do
    setup do
      [
        config: @plugin.build_config(),
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
