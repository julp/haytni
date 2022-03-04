defmodule Haytni.ClearSiteData.BuildConfigTest do
  use Haytni.DataCase, async: true

  describe "Haytni.ClearSiteDataPlugin.build_config/1" do
    test "check default values" do
      config = Haytni.ClearSiteDataPlugin.build_config()

      assert config.__struct__ == Haytni.ClearSiteDataPlugin.Config
      assert config.login == []
      assert config.logout == Haytni.ClearSiteDataPlugin.possible_values()
    end

    test "check :all values" do
      config = Haytni.ClearSiteDataPlugin.build_config(logout: :all)

      assert config.__struct__ == Haytni.ClearSiteDataPlugin.Config
      assert config.login == []
      assert config.logout == Haytni.ClearSiteDataPlugin.possible_values()
    end

    test "check custom valid values" do
      login = ~W[cache]
      logout = ~W[cookies storage *]
      config = Haytni.ClearSiteDataPlugin.build_config(login: login, logout: logout)

      assert config.__struct__ == Haytni.ClearSiteDataPlugin.Config
      assert config.login == login
      assert config.logout == logout
    end

    test "raises on invalid value" do
      assert_raise ArgumentError, ~R'Invalid value: "trackers" for the HTTP header', fn ->
        Haytni.ClearSiteDataPlugin.build_config(logout: ~W[* trackers])
      end      
    end
  end
end
