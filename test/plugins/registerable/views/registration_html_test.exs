defmodule Haytni.Registerable.RegistrationHTMLTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.RegisterablePlugin,
  ]

  defp do_new(conn, params \\ %{}) do
    config = @plugin.build_config()
    conn = get(conn, Routes.haytni_user_registration_path(conn, :new))
    module = @stack
    changeset = if map_size(params) == 0 do
      Haytni.change_user(module)
    else
      {:error, :user, changeset = %Ecto.Changeset{}, _changes_so_far} = Haytni.create_user(module, params)
      changeset
    end
    content = Phoenix.Template.render_to_string(
      HaytniTestWeb.Haytni.User.RegistrationHTML,
      "new",
      "html",
      [
        conn: conn,
        module: module,
        config: config,
        changeset: changeset,
      ]
    )

    assert content =~ "name=\"registration[email]\""
    assert content =~ "name=\"registration[email_confirmation]\""
    assert content =~ "name=\"registration[password]\""
    assert content =~ "name=\"registration[password_confirmation]\""

    content
  end

  test "empty new.html", %{conn: conn} do
    do_new(conn)
  end

  test "new.html with bad params", %{conn: conn} do
    user = user_fixture()
    content = do_new(conn, %{"email" => user.email, "email_confirmation" => user.email, "password" => user.password, "password_confirmation" => user.password})

    assert contains_text?(content, already_took_message())
  end

  defp do_edit(conn, params \\ %{}) do
    user = user_fixture()
    config = @plugin.build_config()
    conn = get(conn, Routes.haytni_user_registration_path(conn, :edit))
    module = @stack
    email_changeset =
      if map_size(params) == 0 do
        @plugin.change_email(module, config, user)
      else
        {:error, changeset = %Ecto.Changeset{}} = @plugin.update_email(module, config, user, "", params)
        changeset
      end

    content =
      Phoenix.Template.render_to_string(
        HaytniTestWeb.Haytni.User.RegistrationHTML,
        "edit",
        "html",
        [
          conn: conn,
          module: module,
          config: config,
          changeset: Haytni.change_user(user),
          email_changeset: email_changeset,
          password_changeset: @plugin.change_password(module, user),
        ]
      )

    assert content =~ "name=\"email[email]\""
    assert content =~ "name=\"current_password\""
    assert content =~ "name=\"password[password]\""
    assert content =~ "name=\"password[password_confirmation]\""
    assert content =~ "name=\"current_password\""

    content
  end

  test "empty edit.html", %{conn: conn} do
    do_edit(conn)
  end

  test "edit.html with bad params", %{conn: conn} do
    content = do_edit(conn, %{"email" => "my@new.email", "current_password" => ""})

    assert contains_text?(content, @plugin.invalid_current_password_message())
  end
end
