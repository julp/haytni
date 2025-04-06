defmodule Haytni.Rememberable.SessionHTMLTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.RememberablePlugin,
  ]

  defp do_test(conn, module, view) do
    config = Haytni.AuthenticablePlugin.build_config()
    changeset = Haytni.AuthenticablePlugin.session_changeset(config)
    conn = get(conn, Routes.haytni_user_session_path(conn, :new))
    Phoenix.Template.render_to_string(view, "new", "html", conn: conn, changeset: changeset, config: config, module: module)
  end

  test "ensures remember checkbox is present without hidden field of the same name for HaytniTestWeb.Haytni", %{conn: conn} do
    content = do_test(conn, HaytniTestWeb.Haytni, HaytniTestWeb.Haytni.User.SessionHTML)

    {:ok, html} = Floki.parse_document(content)
    refute [] == Floki.find(html, "input[name=\"session[remember]\"][type=checkbox][value=true]")
    refute [] == Floki.find(html, "input[name=\"session[remember]\"][type=hidden][value=false]")
#     assert content =~ "name=\"session[remember]\" type=\"checkbox\""
#     refute content =~ "name=\"session[remember]\" type=\"hidden\""
  end

  test "ensures remember checkbox is absent for HaytniTestWeb.HaytniAdmin", %{conn: conn} do
    content = do_test(conn, HaytniTestWeb.HaytniAdmin, HaytniTestWeb.Haytni.Admin.SessionHTML)

    {:ok, html} = Floki.parse_document(content)
    assert [] == Floki.find(html, "input[name=\"session[remember]\"][type=checkbox]")
    assert [] == Floki.find(html, "input[name=\"session[remember]\"][type=hidden]")
#     refute content =~ "name=\"session[remember]\" type=\"checkbox\""
#     refute content =~ "name=\"session[remember]\" type=\"hidden\""
  end
end
