defmodule HaytniWeb.Confirmable.ConfirmationController do
  @moduledoc false

  use HaytniWeb, :controller
  use HaytniWeb.Helpers, Haytni.ConfirmablePlugin
  use Gettext, backend: Haytni.Gettext

  @spec confirmed_message() :: String.t
  def confirmed_message do
    dgettext("haytni", "Your account has been confirmed.")
  end

  @spec confirmation_sent_message() :: String.t
  def confirmation_sent_message do
    dgettext("haytni", "If the provided informations match our database and your email address has not been confirmed yet, you will shortly receive the instructions to do so.")
    |> Haytni.Helpers.concat_spam_check_hint_message()
  end

  # GET /confirmation?confirmation_token=<token>
  # Process the token to confirm an account (if valid)
  def show(conn, %{"confirmation_token" => confirmation_token}, module, config) do
    case Haytni.ConfirmablePlugin.confirm(module, config, confirmation_token) do
      {:ok, _user} ->
        conn
        |> HaytniWeb.Shared.next_step_link(HaytniWeb.Shared.session_path(conn, module), dgettext("haytni", "Continue to sign in"))
        |> HaytniWeb.Shared.render_message(module, confirmed_message())
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

  # GET /confirmation/new
  # Request a new confirmation mail to be sent (and a new token to be generated)
  def new(conn, _params, _module, config) do
    changeset =
      conn
      |> HaytniWeb.Shared.add_referer_to_changeset(Haytni.ConfirmablePlugin.confirmation_request_changeset(config))
    conn
    |> render_new(changeset)
  end

  # POST /confirmation
  # The real magic to ask for a new confirmation token
  def create(conn, %{"confirmation" => confirmation_params}, module, config) do
    case Haytni.ConfirmablePlugin.resend_confirmation_instructions(module, config, confirmation_params) do
      {:ok, _token} ->
        conn
        |> HaytniWeb.Shared.render_message(module, confirmation_sent_message())
      {:error, changeset = %Ecto.Changeset{}} ->
        render_new(conn, changeset)
    end
  end
end
