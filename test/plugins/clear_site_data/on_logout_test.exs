defmodule Haytni.ClearSiteData.OnLogoutTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.ClearSiteDataPlugin,
  ]

  defp do_test(conn, module, config) do
    conn
    |> @plugin.on_logout(module, config)
    |> Plug.Conn.get_resp_header(@plugin.clear_site_data_header_name())
  end

  describe "Haytni.ClearSiteDataPlugin.on_logout/3 (callback)" do
    test "header #{@plugin.clear_site_data_header_name()} is absent if config.logout is []", %{conn: conn} do
      conn
      |> do_test(@stack, @plugin.build_config(logout: []))
      |> (& assert &1 == []).()
    end

    test "header #{@plugin.clear_site_data_header_name()} is present when config.logout is not []", %{conn: conn} do
      conn
      |> do_test(@stack, @plugin.build_config(logout: ~W[storage cookies]))
      |> (& assert &1 == [~S'"storage", "cookies"']).()
    end
  end
end
