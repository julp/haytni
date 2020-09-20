defmodule Haytni.SharedTest do
  use HaytniWeb.ConnCase, async: true

  defp dummy(nil), do: %{__struct__: Dummy}
  defp dummy(referer), do: %{__struct__: Dummy, referer: referer}

  test "back_link/3", %{conn: conn} do
    assert HaytniWeb.Shared.back_link(conn, dummy(nil), nil).assigns.back_link == "/"

    assert HaytniWeb.Shared.back_link(conn, dummy("file:///etc/passwd"), nil).assigns.back_link == "/"
    assert HaytniWeb.Shared.back_link(conn, dummy("file:///etc/passwd"), "https://my.site").assigns.back_link == "https://my.site"
    assert HaytniWeb.Shared.back_link(conn, dummy("https://localhost/login"), nil).assigns.back_link == "https://localhost/login"

#     conn
#     |> Plug.Conn.put_req_header("referer", "javascript:history.back()")
#     |> HaytniWeb.Shared.back_link(dummy("file:///etc/passwd"), nil)
#     |> (& assert &1.assigns.back_link == "/").()
# 
#     conn
#     |> Plug.Conn.put_req_header("referer", "https://localhost/registration/new")
#     |> HaytniWeb.Shared.back_link(dummy("file:///etc/passwd"), nil)
#     |> (& assert &1.assigns.back_link == "https://localhost/registration/new").()
  end

  test "session_path/2", %{conn: conn} do
    assert HaytniWeb.Shared.session_path(conn, HaytniTestWeb.Haytni) == "/session/new"
    assert HaytniWeb.Shared.session_path(HaytniTestWeb.Endpoint, HaytniTestWeb.Haytni) == "/session/new"

    assert HaytniWeb.Shared.session_path(HaytniTestWeb.Endpoint, HaytniTestWeb.HaytniCustomRoutes) == "/CR/login"
  end
end
