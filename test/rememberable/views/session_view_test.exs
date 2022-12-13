defmodule Haytni.Rememberable.SessionViewTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.RememberablePlugin,
  ]
  import Phoenix.View

  defp do_test(conn, module, view) do
    config = Haytni.AuthenticablePlugin.build_config()
    changeset = Haytni.AuthenticablePlugin.session_changeset(config)
    conn = get(conn, Routes.haytni_user_session_path(conn, :new))
    render_to_string(view, "new.html", conn: conn, changeset: changeset, config: config, module: module)
  end

  test "ensures remember checkbox is present without hidden field of the same name for HaytniTestWeb.Haytni", %{conn: conn} do
    content = do_test(conn, HaytniTestWeb.Haytni, HaytniTestWeb.Haytni.User.SessionView)

    assert content =~ "name=\"session[remember]\" type=\"checkbox\""
    refute content =~ "name=\"session[remember]\" type=\"hidden\""
  end

  test "ensures remember checkbox is absent for HaytniTestWeb.HaytniAdmin", %{conn: conn} do
    content = do_test(conn, HaytniTestWeb.HaytniAdmin, HaytniTestWeb.Haytni.Admin.SessionView)

    refute content =~ "name=\"session[remember]\" type=\"checkbox\""
    refute content =~ "name=\"session[remember]\" type=\"hidden\""
  end
end
