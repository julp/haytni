defmodule HaytniWeb.Registerable.RegistrationController do
  @moduledoc false

  use HaytniWeb, :controller
  import Haytni.Gettext

  alias Haytni.Users

  plug Haytni.ViewAndLayoutPlug, :RegistrationView

  defp add_common_assigns(conn) do
    min_pwd_len..max_pwd_len = Haytni.RegisterablePlugin.password_length()
    conn
    |> assign(:minimum_password_length, min_pwd_len)
    |> assign(:maximum_password_length, max_pwd_len)
  end

  defp render_new(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> add_common_assigns()
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  defp handle_signed_in!(conn = %Plug.Conn{}) do
    conn
    |> redirect(to: "/")
    |> halt()
  end

  def new(conn, _params) do
    case conn.assigns[:current_user] do
      nil ->
        render_new(conn, Users.change_user())
      _current_user ->
        handle_signed_in!(conn)
    end
  end

  @msgid ~S"""
  A final step is required before you fully dispose of your account: in order to confirm your address, an email has been sent to %{email}, which contains a link you need to activate. Once done, you will be able to login.

  Check your spam folder if necessary.
  """
  def create(conn, %{"registration" => registration_params}) do
    case conn.assigns[:current_user] do
      nil ->
        case Haytni.create_user(registration_params) do
          {:ok, %{user: user}} ->
            session_path = Haytni.router().session_path(conn, :new)
            if Haytni.plugin_enabled?(Haytni.ConfirmablePlugin) do
              conn
              |> HaytniWeb.Shared.next_step_link(session_path, dgettext("haytni", "I have confirmed my account, continue to sign in"))
              |> HaytniWeb.Shared.render_message(dgettext("haytni", @msgid, email: user.email))
            else
              conn
              |> redirect(to: session_path)
              |> halt()
            end
          {:error, :user, changeset = %Ecto.Changeset{}, _changes_so_far} ->
            render_new(conn, changeset)
          # other error case: let it crash
        end
      _current_user ->
        handle_signed_in!(conn)
    end
  end

  defp render_edit(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> add_common_assigns()
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def edit(conn, _params) do
    case conn.assigns[:current_user] do
      nil ->
        handle_signed_in!(conn)
      current_user ->
        conn
        |> render_edit(Users.change_user(current_user))
    end
  end

  def update(conn, %{"registration" => registration_params}) do
    case conn.assigns[:current_user] do
      nil ->
        handle_signed_in!(conn)
      current_user ->
        case Haytni.update_registration(current_user, registration_params) do
          {:ok, %{user: current_user}} ->
            conn
            |> put_flash(:info, dgettext("haytni", "Informations have been updated"))
            |> render_edit(Users.change_user(current_user))
          {:error, :user, changeset = %Ecto.Changeset{}, _changes_so_far} ->
            render_edit(conn, changeset)
          # other error case: let it crash
        end
    end
  end
end
