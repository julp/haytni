defmodule Haytni.Registerable.RegistrationViewTest do
  use HaytniWeb.ConnCase, async: true
  import Phoenix.View

  defp do_new(conn, params \\ %{}) do
    conn = get(conn, Routes.registration_path(conn, :new))
    module = HaytniTestWeb.Haytni
    changeset = if map_size(params) == 0 do
      Haytni.change_user(module)
    else
      {:error, :user, changeset = %Ecto.Changeset{}, _changes_so_far} = Haytni.create_user(module, params)
      changeset
    end
    content = render_to_string(HaytniTestWeb.Haytni.RegistrationView, "new.html", conn: conn, changeset: changeset, module: module)

    assert String.contains?(content, "name=\"registration[email]\"")
    assert String.contains?(content, "name=\"registration[email_confirmation]\"")
    assert String.contains?(content, "name=\"registration[password]\"")
    assert String.contains?(content, "name=\"registration[password_confirmation]\"")

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
    conn = get(conn, Routes.registration_path(conn, :edit))
    module = HaytniTestWeb.Haytni
    changeset = if map_size(params) == 0 do
      Haytni.change_user(module, user)
    else
      {:error, :user, changeset = %Ecto.Changeset{}, _changes_so_far} = Haytni.update_registration(module, user, params)
      changeset
    end
    content = render_to_string(HaytniTestWeb.Haytni.RegistrationView, "edit.html", conn: conn, changeset: changeset, module: module)

    assert String.contains?(content, "name=\"registration[email]\"")
    assert String.contains?(content, "name=\"registration[password]\"")
    assert String.contains?(content, "name=\"registration[password_confirmation]\"")

    content
  end

  test "empty edit.html", %{conn: conn} do
    do_edit(conn)
  end

  test "edit.html with bad params", %{conn: conn} do
    content = do_edit(conn, %{"email" => "my@new.email"})

    assert contains_text?(content, empty_message())
  end
end
