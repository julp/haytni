defmodule Haytni.ClearSiteData.OnLogoutTest do
  use HaytniWeb.ConnCase, async: true

  defp do_test(conn, module, config) do
    conn
    |> Haytni.ClearSiteDataPlugin.on_logout(module, config)
    |> Plug.Conn.get_resp_header(Haytni.ClearSiteDataPlugin.clear_site_data_header_name())
  end

  describe "Haytni.ClearSiteDataPlugin.on_logout/3 (callback)" do
    setup do
      [
        module: HaytniTestWeb.Haytni,
      ]
    end

    test "header #{Haytni.ClearSiteDataPlugin.clear_site_data_header_name()} is absent if config.logout is []", %{module: module, conn: conn} do
      conn
      |> do_test(module, Haytni.ClearSiteDataPlugin.build_config(logout: []))
      |> (& assert &1 == []).()
    end

    test "header #{Haytni.ClearSiteDataPlugin.clear_site_data_header_name()} is present when config.logout is not []", %{module: module, conn: conn} do
      conn
      |> do_test(module, Haytni.ClearSiteDataPlugin.build_config(logout: ~W[storage cookies]))
      |> (& assert &1 == [~S'"storage", "cookies"']).()
    end
  end
end
