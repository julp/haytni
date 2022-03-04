defmodule Haytni.ClearSiteData.OnSuccessfulAuthentificationTest do
  use HaytniWeb.ConnCase, async: true

  defp do_test(conn, module, config) do
    keywords = []
    multi = Ecto.Multi.new()

    {conn, ^multi, ^keywords} = Haytni.ClearSiteDataPlugin.on_successful_authentication(conn, nil, multi, keywords, module, config)
    Plug.Conn.get_resp_header(conn, Haytni.ClearSiteDataPlugin.clear_site_data_header_name())
  end

  describe "Haytni.ClearSiteDataPlugin.on_successful_authentication/6 (callback)" do
    setup do
      [
        module: HaytniTestWeb.Haytni,
      ]
    end

    test "header #{Haytni.ClearSiteDataPlugin.clear_site_data_header_name()} is absent if config.login is []", %{module: module, conn: conn} do
      conn
      |> do_test(module, Haytni.ClearSiteDataPlugin.build_config(login: []))
      |> (& assert &1 == []).()
    end

    test "header #{Haytni.ClearSiteDataPlugin.clear_site_data_header_name()} is present when config.login is not []", %{module: module, conn: conn} do
      conn
      |> do_test(module, Haytni.ClearSiteDataPlugin.build_config(login: ~W[cookies * storage]))
      |> (& assert &1 == [~S'"cookies", "*", "storage"']).()
    end
  end
end
