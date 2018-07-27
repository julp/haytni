defmodule HaytniWeb.Confirmable.ConfirmationController do
  @moduledoc false

  use HaytniWeb, :controller
  import Haytni.Gettext

  alias Haytni.Confirmation
  alias Haytni.ConfirmablePlugin

  plug Haytni.ViewAndLayoutPlug, :ConfirmationView

  # GET /confirmation?confirmation_token=<token>
  # Process the token to confirm an account (if valid)
  def show(conn, %{"confirmation_token" => confirmation_token}) do
    case ConfirmablePlugin.confirm(confirmation_token) do
      {:error, message} ->
        conn
        |> HaytniWeb.Shared.render_message(message, :error)
      _user = %_{} ->
        conn
        |> HaytniWeb.Shared.next_step_link(session_path(conn), dgettext("haytni", "Continue to sign in"))
        |> HaytniWeb.Shared.render_message(dgettext("haytni", "Your account has been confirmed."))
    end
  end

  defp render_new(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  # GET /confirmation/new
  # Request a new confirmation mail to be sent (and a new token to be generated)
  def new(conn, _params) do
    changeset = conn
    |> HaytniWeb.Shared.add_referer_to_changeset(Confirmation.change_confirmation())
    conn
    |> render_new(changeset)
  end

  # POST /confirmation
  # The real magic to ask for a new confirmation token
  def create(conn, %{"confirmation" => confirmation_params}) do
    case Confirmation.create_confirmation(confirmation_params) do
      {:error, %Ecto.Changeset{} = changeset} ->
        render_new(conn, changeset)
      {:ok, confirmation} ->
        confirmation
        |> ConfirmablePlugin.resend_confirmation_instructions()
        |> handle_reconfirmation_result(conn, confirmation)
    end
  end

  defp handle_reconfirmation_result({:ok, _user}, conn, _confirmation) do
    conn
    |> HaytniWeb.Shared.render_message(dgettext("haytni", "A new confirmation has been sent."))
  end

  defp handle_reconfirmation_result({:error, :already_confirmed}, conn, confirmation) do
    conn
    |> HaytniWeb.Shared.back_link(confirmation, session_path(conn))
    |> HaytniWeb.Shared.render_message(dgettext("haytni", "This account has already been confirmed"), :error)
  end

  defp handle_reconfirmation_result({:error, :no_match}, conn, confirmation) do
    changeset = confirmation
    |> Confirmation.change_confirmation()
    |> Haytni.mark_changeset_keys_as_unmatched(ConfirmablePlugin.confirmation_keys())
    render_new(conn, changeset)
  end

  defp session_path(conn) do
    Haytni.router().session_path(conn, :new)
  end
end
