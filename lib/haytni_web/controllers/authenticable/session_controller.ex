defmodule HaytniWeb.Authenticable.SessionController do
  @moduledoc false

  use HaytniWeb, :controller
  use HaytniWeb.Helpers, Haytni.AuthenticablePlugin

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

  def new(conn, _params, _module, config) do
    render_new(conn, Haytni.AuthenticablePlugin.session_changeset(config))
  end

  def create(conn, %{"session" => session_params}, module, config) do
    case Haytni.AuthenticablePlugin.authenticate(conn, module, config, session_params) do
      {:ok, conn} ->
        conn
        |> redirect()
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> render_new(changeset)
    end
  end

  def delete(conn, _params, module, _config) do
    conn
    |> Haytni.logout(module)
    |> redirect()
  end
end
