defmodule HaytniWeb.Authenticable.SessionController do
  @moduledoc false

  use HaytniWeb, :controller
  use HaytniWeb.Helpers, {Haytni.AuthenticablePlugin, :with_current_user}

  defp redirect(conn) do
    conn
    |> redirect(to: "/")
    |> halt()
  end

  defp render_new(conn, changeset = %Ecto.Changeset{}) do
    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def new(conn, _params, nil, _module, config) do
    render_new(conn, Haytni.AuthenticablePlugin.session_changeset(config))
  end

  def new(conn, _params, _current_user, _module, _config) do
    redirect(conn)
  end

  def create(conn, %{"session" => session_params}, nil, module, config) do
    case Haytni.AuthenticablePlugin.authenticate(conn, module, config, session_params) do
      {:ok, conn} ->
        conn
        |> redirect()
      {:error, changeset = %Ecto.Changeset{}} ->
        conn
        |> put_resp_header("x-suspicious-activity", "1")
        |> render_new(changeset)
    end
  end

  def create(conn, _params, _current_user, _module, _config) do
    redirect(conn)
  end

  def delete(conn, _params, nil, _module, _config) do
    redirect(conn)
  end

  def delete(conn, _params, _current_user, module, _config) do
    conn
    |> Haytni.logout(module)
    |> redirect()
  end
end
