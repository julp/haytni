defmodule HaytniWeb.Registerable.RegistrationController do
  @moduledoc false

  use HaytniWeb, :controller
  use HaytniWeb.Helpers, {Haytni.RegisterablePlugin, :with_current_user}
  import Haytni.Gettext

  def registration_disabled_message do
    dgettext("haytni", "Sorry, new registrations are currently closed")
  end

  defp render_new_when_disabled_registration(conn, module) do
    conn
    |> HaytniWeb.Shared.render_message(module, registration_disabled_message(), :error)
  end

  defp render_new(conn, changeset = %Ecto.Changeset{}) do
    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  defp handle_signed_in!(conn) do
    conn
    |> redirect(to: "/")
    |> halt()
  end

  def new(conn, _params, nil, module, %{registration_disabled?: true}) do
    render_new_when_disabled_registration(conn, module)
  end

  def new(conn, params, nil, module, _config) do
    params = if Haytni.plugin_enabled?(module, Haytni.InvitablePlugin) do
      params
      |> Map.take(~W[invitation email])
      |> Map.put("email_confirmation", Map.get(params, "email"))
    else
      %{}
    end
    render_new(conn, Haytni.change_user(module, params))
  end

  def new(conn, _params, _current_user, _module, _config) do
    handle_signed_in!(conn)
  end

  @spec account_to_be_confirmed_message(user :: Haytni.user) :: String.t
  def account_to_be_confirmed_message(user) do
    dgettext("haytni", "A final step is required before you fully dispose of your account: in order to confirm your address, an email has been sent to %{email}, which contains a link you need to activate. Once done, you will be able to login.", email: user.email)
    |> Haytni.Helpers.concat_spam_check_hint_message()
  end

  def create(conn, _params, nil, module, %{registration_disabled?: true}) do
    render_new_when_disabled_registration(conn, module)
  end

  def create(conn, %{"registration" => registration_params}, nil, module, _config) do
    case Haytni.create_user(module, registration_params) do
      {:ok, %{user: user}} ->
        session_path = HaytniWeb.Shared.session_path(conn, module)
        if Haytni.plugin_enabled?(module, Haytni.ConfirmablePlugin) do
          conn
          |> HaytniWeb.Shared.next_step_link(session_path, dgettext("haytni", "I have confirmed my account, continue to sign in"))
          |> HaytniWeb.Shared.render_message(module, account_to_be_confirmed_message(user))
        else
          conn
          |> redirect(to: session_path)
          |> halt()
        end
      {:error, :user, changeset = %Ecto.Changeset{}, _changes_so_far} ->
        conn
        |> HaytniWeb.Helpers.set_suspicious_activity()
        |> render_new(changeset)
      # other error case: let it crash
    end
  end

  def create(conn, _params, _current_user, _module, _config) do
    handle_signed_in!(conn)
  end

  defp render_edit(conn, changeset = %Ecto.Changeset{}) do
    conn
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def edit(conn, _params, nil, _module, _config) do
    handle_signed_in!(conn)
  end

  def edit(conn, _params, current_user, _module, _config) do
    render_edit(conn, Haytni.change_user(current_user))
  end

  @spec successful_edition_message() :: String.t
  def successful_edition_message do
    dgettext("haytni", "Informations have been updated")
  end

  def update(conn, _params, nil, _module, _config) do
    handle_signed_in!(conn)
  end

  def update(conn, %{"registration" => registration_params}, current_user, module, _config) do
    case Haytni.update_registration(module, current_user, registration_params) do
      {:ok, %{user: _current_user}} ->
        conn
        |> put_flash(:info, successful_edition_message())
        |> render_edit(Haytni.change_user(current_user))
      {:error, :user, changeset = %Ecto.Changeset{}, _changes_so_far} ->
        render_edit(conn, changeset)
      # other error case: let it crash
    end
  end
end
