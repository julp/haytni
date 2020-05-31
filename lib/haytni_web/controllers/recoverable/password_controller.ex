defmodule HaytniWeb.Recoverable.PasswordController do
  @moduledoc false

  use HaytniWeb, :controller
  use HaytniWeb.Helpers, Haytni.RecoverablePlugin
  import Haytni.Gettext

  defp render_new(conn, changeset = %Ecto.Changeset{}) do
    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  # GET /password/new
  # To request a new key, sent by mail, in order to change its password
  def new(conn, _params, _module, config) do
    conn
    |> render_new(Haytni.RecoverablePlugin.recovering_changeset(config))
  end

  @msgid ~S"""
  To reset your password we sent you an email containing a link you will need to follow.

  Hint: don't forget to look in the spams folder.
  """
  @spec recovery_token_sent_message() :: String.t
  def recovery_token_sent_message do
    dgettext("haytni", @msgid)
  end

  # POST /password
  # Send by email a new token to reset password
  def create(conn, %{"password" => password_params}, module, config) do
    case Haytni.RecoverablePlugin.send_reset_password_instructions(module, config, password_params) do
      {:ok, _user} ->
        conn
        |> HaytniWeb.Shared.render_message(module, recovery_token_sent_message())
      {:error, changeset = %Ecto.Changeset{}} ->
        render_new(conn, changeset)
    end
  end

  defp render_edit(conn, changeset = %Ecto.Changeset{}) do
    conn
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  # GET /password/edit?reset_password_token=<reset_password_token>
  # Request a new password
  def edit(conn, params = %{"reset_password_token" => _reset_password_token}, module, _config) do
    conn
    |> render_edit(Haytni.Recoverable.PasswordChange.change_password(module, params))
  end

  @spec password_changed_message() :: String.t
  def password_changed_message do
    dgettext("haytni", "Your password has been successfully changed.")
  end

  # PATCH /password
  # Redefine the password of the targeted account
  def update(conn, %{"password" => password_params}, module, config) do
    case Haytni.RecoverablePlugin.recover(module, config, password_params) do
      {:ok, _user} ->
        conn
        |> HaytniWeb.Shared.next_step_link(HaytniWeb.Shared.session_path(conn, module), dgettext("haytni", "Password changed, continue to sign in"))
        |> HaytniWeb.Shared.render_message(module, password_changed_message())
      {:error, changeset = %Ecto.Changeset{}} ->
        render_edit(conn, changeset)
    end
  end
end
