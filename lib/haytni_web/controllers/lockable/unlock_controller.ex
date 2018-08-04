defmodule HaytniWeb.Lockable.UnlockController do
  @moduledoc false

  use HaytniWeb, :controller
  import Haytni.Gettext

  alias Haytni.LockablePlugin
  alias Haytni.Unlockable.Request

  plug Haytni.ViewAndLayoutPlug, :UnlockView

  # GET /unlock?unlock_token=<token>
  # Process the token to unlock an account (if valid)
  def show(conn, %{"unlock_token" => unlock_token}) do
    case LockablePlugin.unlock(unlock_token) do
      {:error, message} ->
        conn
        |> HaytniWeb.Shared.render_message(message, :error)
      _user = %_{} ->
        conn
        |> HaytniWeb.Shared.next_step_link(Haytni.router().session_path(conn, :new), dgettext("haytni", "I get it, continue to sign in"))
        |> HaytniWeb.Shared.render_message(dgettext("haytni", "Your account has been unlocked."))
    end
  end

  defp render_new(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  # GET /unlock/new
  # To request a new key to unlock its account to be sent by mail
  def new(conn, _params) do
    changeset = conn
    |> HaytniWeb.Shared.add_referer_to_changeset(Request.change_request())
    conn
    |> render_new(changeset)
  end

  # POST /unlock
  # Handle the request for account unlocking
  def create(conn, %{"unlock" => unlock_params}) do
    case Request.create_request(unlock_params) do
      {:error, %Ecto.Changeset{} = changeset} ->
        render_new(conn, changeset)
      {:ok, request} ->
        request
        |> LockablePlugin.resend_unlock_instructions()
        |> handle_unlock_request(conn, request)
    end
  end

  @msgid ~S"""
  Check your emails, a new key to unlock your account has been sent.

  You may need to look at the spams folder.
  """
  defp handle_unlock_request({:ok, _user}, conn, _request) do
    conn
    |> HaytniWeb.Shared.render_message(dgettext("haytni", @msgid))
  end

  defp handle_unlock_request({:error, :not_locked}, conn, request) do
    conn
    |> HaytniWeb.Shared.back_link(request, Haytni.router().session_path(conn, :new))
    |> HaytniWeb.Shared.render_message(dgettext("haytni", "This account is not currently locked"), :error)
  end

  defp handle_unlock_request({:error, :no_match}, conn, request) do
    changeset = request
    |> Request.change_request()
    |> Haytni.mark_changeset_keys_as_unmatched(LockablePlugin.unlock_keys())
    render_new(conn, changeset)
  end
end
