defmodule Haytni.Rolable.RoleHTMLTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.RolablePlugin,
  ]

  defp do_new(conn, params) do
    changeset =
      if params == %{} do
        @plugin.change_role(@stack)
      else
        {:error, changeset} =
          %HaytniTest.UserRole{}
          |> HaytniTest.UserRole.changeset(params)
          |> Ecto.Changeset.apply_action(:insert)

        changeset
      end

    content =
      Phoenix.Template.render_to_string(
        HaytniTestWeb.Haytni.User.RoleHTML,
        "new",
        "html",
        [
          conn: conn,
          module: @stack,
          changeset: changeset,
          role_path_2: &HaytniTestWeb.Router.Helpers.haytni_user_role_path/2,
          role_path_3: &HaytniTestWeb.Router.Helpers.haytni_user_role_path/3,
        ]
      )

    assert content =~ "name=\"role[name]\""

    if params != %{} do
      assert contains_text?(content, empty_message())
    end
  end

  defp do_edit(conn, params) do
    role = %HaytniTest.UserRole{id: 42, name: "it was valid"}
    changeset =
      if params == %{} do
        @plugin.change_role(role)
      else
        {:error, changeset} =
          role
          |> HaytniTest.UserRole.changeset(params)
          |> Ecto.Changeset.apply_action(:update)

        changeset
      end

    content =
      Phoenix.Template.render_to_string(
        HaytniTestWeb.Haytni.User.RoleHTML,
        "edit",
        "html",
        [
          conn: conn,
          role: role,
          module: @stack,
          changeset: changeset,
          role_path_2: &HaytniTestWeb.Router.Helpers.haytni_user_role_path/2,
          role_path_3: &HaytniTestWeb.Router.Helpers.haytni_user_role_path/3,
        ]
      )

    assert content =~ "name=\"role[name]\""

    if params != %{} do
      assert contains_text?(content, empty_message())
    end
  end

  test "renders \"empty\" new.html", %{conn: conn} do
    do_new(conn, %{})
  end

  # NOTE: the purpose of this test is to check that changeset errors are displayed
  # previously I've forgotten to apply an action so they weren't shown in several places
  # we kinda simulate a create action (which renders also new.html)
  test "renders new.html with bad params", %{conn: conn} do
    do_new(conn, %{"name" => ""})
  end

  test "renders \"empty\" edit.html", %{conn: conn} do
    do_edit(conn, %{})
  end

  test "renders edit.html with bad params", %{conn: conn} do
    do_edit(conn, %{"name" => ""})
  end

  test "renders index.html", %{conn: conn} do
    roles = [
      %HaytniTest.UserRole{id: 1, name: "FOO"},
      %HaytniTest.UserRole{id: 3, name: "BAR"},
    ]

    content =
      Phoenix.Template.render_to_string(
        HaytniTestWeb.Haytni.User.RoleHTML,
        "index",
        "html",
        [
          conn: conn,
          roles: roles,
          module: @stack,
          role_path_2: &HaytniTestWeb.Router.Helpers.haytni_user_role_path/2,
          role_path_3: &HaytniTestWeb.Router.Helpers.haytni_user_role_path/3,
        ]
      )

    {xmerl, _} =
      content
      |> :erlang.binary_to_list()
      |> :xmerl_scan.string()

    for role <- roles do
#       assert content =~ "<td>#{role.name}</td>"
      "//td/descendant-or-self::*[contains(text(), '#{role.name}')]"
      |> :erlang.binary_to_list()
      |> :xmerl_xpath.string(xmerl)
      |> (& refute &1 == []).()

      assert content =~ "href=\"#{HaytniTestWeb.Router.Helpers.haytni_user_role_path(conn, :edit, role.id)}\""
    end
  end
end
