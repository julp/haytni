defmodule HaytniWeb.Authenticable.SessionController do
  @moduledoc false

  use HaytniWeb, :controller

  alias Haytni.Session

  plug Haytni.ViewAndLayoutPlug, :SessionView

  defp redirect(conn) do
    conn
    |> redirect(to: "/")
    |> halt()
  end

  defp render_new(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def new(conn, _params) do
    render_new(conn, Session.change_session())
  end

  def create(conn, %{"session" => session_params}) do
    case Session.create_session(session_params) do
      {:ok, session} ->
        case Haytni.AuthenticablePlugin.authentificate(conn, session) do
          {:ok, conn} ->
            conn
            |> put_session(:user_id, conn.assigns.current_user.id)
            |> configure_session(renew: true)
            |> redirect()
          {:error, message} ->
            conn
            |> put_flash(:error, message)
            |> render_new(Session.change_session(session))
        end
      {:error, changeset} ->
        render_new(conn, changeset)
    end
  end

  def delete(conn, _params) do
    conn
    |> Haytni.logout()
    |> configure_session(drop: true)
    |> redirect()
  end
end
