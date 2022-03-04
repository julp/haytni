defmodule Haytni.Registerable.RegistrationViewTest do
  use HaytniWeb.ConnCase, async: true
  import Phoenix.View

  defp do_new(conn, params \\ %{}) do
    conn = get(conn, Routes.haytni_user_registration_path(conn, :new))
    module = HaytniTestWeb.Haytni
    changeset = if map_size(params) == 0 do
      Haytni.change_user(module)
    else
      {:error, :user, changeset = %Ecto.Changeset{}, _changes_so_far} = Haytni.create_user(module, params)
      changeset
    end
    content = render_to_string(HaytniTestWeb.Haytni.User.RegistrationView, "new.html", conn: conn, changeset: changeset, module: module)

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
    config = Haytni.RegisterablePlugin.build_config()
    conn = get(conn, Routes.haytni_user_registration_path(conn, :edit))
    module = HaytniTestWeb.Haytni
    email_changeset = if map_size(params) == 0 do
      Haytni.RegisterablePlugin.change_email(module, config, user)
    else
      {:error, changeset = %Ecto.Changeset{}} = Haytni.RegisterablePlugin.update_email(module, config, user, "", params)
      changeset
    end
    content = render_to_string(
      HaytniTestWeb.Haytni.User.RegistrationView,
      "edit.html",
      [
        conn: conn,
        module: module,
        changeset: Haytni.change_user(user),
        email_changeset: email_changeset,
        password_changeset: Haytni.RegisterablePlugin.change_password(module, user),
      ]
    )

    assert content =~ "name=\"email[email]\""
    assert content =~ "name=\"email[current_password]\""
    assert content =~ "name=\"password[password]\""
    assert content =~ "name=\"password[password_confirmation]\""
    assert content =~ "name=\"password[current_password]\""

    content
  end

  test "empty edit.html", %{conn: conn} do
    do_edit(conn)
  end

  test "edit.html with bad params", %{conn: conn} do
    content = do_edit(conn, %{"email" => "my@new.email"})

    assert contains_text?(content, Haytni.RegisterablePlugin.invalid_current_password_message())
  end
end
