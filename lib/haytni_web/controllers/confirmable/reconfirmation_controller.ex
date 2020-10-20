defmodule HaytniWeb.Confirmable.ReconfirmationController do
  @moduledoc false

  use HaytniWeb, :controller
  use HaytniWeb.Helpers, {Haytni.ConfirmablePlugin, :with_current_user}
  import Haytni.Gettext

  @spec address_updated_message() :: String.t
  def address_updated_message do
    dgettext("haytni", "Your email address has been updated")
  end

  @spec not_logged_in_message() :: String.t
  def not_logged_in_message do
    dgettext("haytni", "To proceed to email change you have to be logged in")
  end

  # GET /reconfirmation?confirmation_token=<token>
  # Process the token to reconfirm (following an email address change) an account (if valid)
  def show(conn, _params, nil, module, _config) do
    conn
    #|> put_flash(:error, not_logged_in_message())
    #|> redirect(to: HaytniWeb.Shared.haytni_path(conn, module, &(:"haytni_#{&1}_session_path"), :new))
    #|> halt()
    |> HaytniWeb.Shared.next_step_link(HaytniWeb.Shared.session_path(conn, module), dgettext("haytni", "Continue to sign in"))
    |> HaytniWeb.Shared.render_message(module, not_logged_in_message(), :error)
  end

  def show(conn, %{"confirmation_token" => confirmation_token}, current_user, module, config) do
    case Haytni.ConfirmablePlugin.reconfirm(module, config, current_user, confirmation_token) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, address_updated_message())
        |> redirect(to: HaytniWeb.Shared.haytni_path(conn, module, &(:"haytni_#{&1}_registration_path"), :edit))
        |> halt()
      {:error, message} ->
        conn
        |> HaytniWeb.Shared.render_message(module, message, :error)
    end
  end
end
