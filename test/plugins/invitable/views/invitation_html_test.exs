defmodule Haytni.Invitable.InvitationHTMLTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.InvitablePlugin,
  ]

  setup %{conn: conn} do
    conn =
      conn
      |> assign(:current_user, user_fixture())
      |> get(Routes.haytni_user_invitation_path(conn, :new))

    [
      conn: conn,
      config: @plugin.build_config(),
    ]
  end

  defp do_test(conn, config, params) do
    changeset =
      if map_size(params) == 0 do
        conn.assigns.current_user
        |> @plugin.build_and_assoc_invitation()
        |> @plugin.invitation_to_changeset(config)
      else
        {:error, changeset} = @plugin.send_invitation(@stack, config, params, conn.assigns.current_user)
        changeset
      end
    content = Phoenix.Template.render_to_string(HaytniTestWeb.Haytni.User.InvitationHTML, "new", "html", conn: conn, changeset: changeset, config: config, module: @stack)

    assert content =~ "name=\"invitation[sent_to]\""

    if map_size(params) != 0 do
      assert contains_text?(content, invalid_format_message())
    end
  end

  test "renders \"empty\" new.html", %{conn: conn, config: config} do
    do_test(conn, config, %{})
  end

  # NOTE: the purpose of this test is to check that changeset errors are displayed
  # previously I've forgotten to apply an action so they weren't shown in several places
  # we kinda simulate a create action (which renders also new.html)
  test "renders new.html with bad params", %{conn: conn, config: config} do
    do_test(conn, config, %{"sent_to" => "Monsieur le Président"})
  end
end
