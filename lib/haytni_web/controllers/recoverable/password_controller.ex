defmodule HaytniWeb.Recoverable.PasswordController do
  @moduledoc false

  use HaytniWeb, :controller
  import Haytni.Gettext

  alias Haytni.RecoverablePlugin
  alias Haytni.Recoverable.ResetRequest
  alias Haytni.Recoverable.PasswordChange

  plug Haytni.ViewAndLayoutPlug, :PasswordView

  defp render_new(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  # GET /password/new
  # To request a new key, sent by mail, in order to change its password
  def new(conn, _params) do
    conn
    |> render_new(ResetRequest.change_request())
  end

  # POST /password
  # Send by email a new token to reset password
  def create(conn, %{"password" => password_params}) do
    case ResetRequest.create_request(password_params) do
      {:error, %Ecto.Changeset{} = changeset} ->
        render_new(conn, changeset)
      {:ok, request} ->
        request
        |> RecoverablePlugin.send_reset_password_instructions()
        |> handle_request_result(conn, request)
    end
  end

  @msgid ~S"""
  To reset your password we sent you an email containing a link you will need to follow.

  Hint: don't forget to look in the spams folder.
  """
  defp handle_request_result({:ok, _user}, conn, _request) do
    conn
    |> HaytniWeb.Shared.render_message(dgettext("haytni", @msgid))
  end

  defp handle_request_result({:error, :no_match}, conn, request) do
    changeset = request
    |> ResetRequest.change_request()
    |> Haytni.mark_changeset_keys_as_unmatched(RecoverablePlugin.reset_password_keys())
    render_new(conn, changeset)
  end

  defp render_edit(conn, %Ecto.Changeset{} = changeset) do
    min_pwd_len..max_pwd_len = Haytni.RegisterablePlugin.password_length()
    conn
    |> assign(:minimum_password_length, min_pwd_len)
    |> assign(:maximum_password_length, max_pwd_len)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  # GET /password/edit?reset_password_token=<reset_password_token>
  # Request a new password
  def edit(conn, params = %{"reset_password_token" => _reset_password_token}) do
    conn
    |> render_edit(PasswordChange.change_password(params))
  end

  # PATCH /password
  # Redefine the password of the targeted account
  def update(conn, %{"password" => password_params}) do
    case PasswordChange.create_password(password_params) do
      {:error, %Ecto.Changeset{} = changeset} ->
        render_edit(conn, changeset)
      {:ok, change} ->
        case RecoverablePlugin.recover(change.reset_password_token, change.password) do
          {:error, message} ->
            changeset = change
            |> PasswordChange.change_password()
            |> Ecto.Changeset.add_error(:reset_password_token, message)
            |> Map.put(:action, :insert)
            render_edit(conn, changeset)
          _user = %_{} ->
            conn
            |> HaytniWeb.Shared.next_step_link(Haytni.router().session_path(conn, :new), dgettext("haytni", "Password changed, continue to sign in"))
            |> HaytniWeb.Shared.render_message(dgettext("haytni", "Your password has been successfully changed."))
        end
    end
  end
end
