defmodule Haytni.Rememberable.OnLogoutTest do
  use HaytniWeb.ConnCase, async: true

  describe "Haytni.Rememberable.on_logout/1 (callback)" do
    test "ensures rememberme cookie is removed (asked for removal to the client) on logout", %{conn: conn} do
      conn = conn
      |> add_rememberme_cookie("azerty")
      |> Haytni.RememberablePlugin.on_logout()

      remember_cookie = Map.get(conn.resp_cookies, Haytni.RememberablePlugin.remember_cookie_name())

      assert %{max_age: 0, universal_time: {{1970, 1, 1}, {0, 0, 0}}} = remember_cookie
      refute Map.has_key?(remember_cookie, :value)
    end
  end
end
