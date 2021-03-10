defmodule HaytniWeb.Lockable.UnlockController do
  @moduledoc false

  use HaytniWeb, :controller
  use HaytniWeb.Helpers, Haytni.LockablePlugin
  import Haytni.Gettext

  @spec unlock_message() :: String.t
  def unlock_message do
    dgettext("haytni", "Your account has been unlocked.")
  end

  # GET /unlock?unlock_token=<token>
  # Process the token to unlock an account (if valid)
  def show(conn, %{"unlock_token" => unlock_token}, module, config) do
    case Haytni.LockablePlugin.unlock(module, config, unlock_token) do
      {:ok, _user} ->
        conn
        |> HaytniWeb.Shared.next_step_link(HaytniWeb.Shared.session_path(conn, module), dgettext("haytni", "I get it, continue to sign in"))
        |> HaytniWeb.Shared.render_message(module, unlock_message())
      {:error, message} ->
        conn
        |> HaytniWeb.Shared.render_message(module, message, :error)
    end
  end

  defp render_new(conn, changeset = %Ecto.Changeset{}) do
    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  # GET /unlock/new
  # To request a new key to unlock its account to be sent by mail
  def new(conn, _params, _module, config) do
    changeset =
      conn
      |> HaytniWeb.Shared.add_referer_to_changeset(Haytni.LockablePlugin.unlock_request_changeset(config))
    conn
    |> render_new(changeset)
  end

  @spec new_token_sent_message() :: String.t
  def new_token_sent_message do
    if Application.get_env(:haytni, :mode) == :strict do
      dgettext("haytni", "If the provided informations match our database, you will shortly receive the instructions by mail to recover your account.")
    else
      dgettext("haytni", "Check your emails, a new key to unlock your account has been sent.")
    end
    |> Haytni.Helpers.concat_spam_check_hint_message()
  end

  # POST /unlock
  # Handle the request for account unlocking
  def create(conn, %{"unlock" => unlock_params}, module, config) do
    case Haytni.LockablePlugin.resend_unlock_instructions(module, config, unlock_params) do
      {:ok, _user} ->
        conn
        |> HaytniWeb.Shared.render_message(module, new_token_sent_message())
      {:error, changeset = %Ecto.Changeset{}} ->
        render_new(conn, changeset)
    end
  end
end
