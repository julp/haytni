defmodule Haytni.ClearSiteData.OnSuccessfulAuthentificationTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.ClearSiteDataPlugin,
  ]

  defp do_test(conn, module, config) do
    keywords = []
    multi = Ecto.Multi.new()

    {conn, ^multi, ^keywords} = @plugin.on_successful_authentication(conn, nil, multi, keywords, module, config)
    Plug.Conn.get_resp_header(conn, @plugin.clear_site_data_header_name())
  end

  describe "Haytni.ClearSiteDataPlugin.on_successful_authentication/6 (callback)" do
    test "header #{@plugin.clear_site_data_header_name()} is absent if config.login is []", %{conn: conn} do
      conn
      |> do_test(@stack, @plugin.build_config(login: []))
      |> (& assert &1 == []).()
    end

    test "header #{@plugin.clear_site_data_header_name()} is present when config.login is not []", %{conn: conn} do
      conn
      |> do_test(@stack, @plugin.build_config(login: ~W[cookies * storage]))
      |> (& assert &1 == [~S'"cookies", "*", "storage"']).()
    end
  end
end
