defmodule HaytniWeb.Authenticable.SessionController do
  @moduledoc false

  use HaytniWeb, :controller
  use HaytniWeb.Helpers, {Haytni.AuthenticablePlugin, :with_current_user}

  defp redirect_to(conn, path) do
    conn
    |> redirect(to: path)
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

  def new(conn, _params, _current_user, _module, config) do
    redirect_to(conn, config.sign_in_return_path)
  end

  def create(conn, %{"session" => session_params}, nil, module, config) do
    case Haytni.AuthenticablePlugin.authenticate(conn, module, config, session_params) do
      {:ok, conn} ->
        redirect_to(conn, config.sign_in_return_path)
      {:error, changeset = %Ecto.Changeset{}} ->
        conn
        |> HaytniWeb.Helpers.set_suspicious_activity()
        |> render_new(changeset)
    end
  end

  def create(conn, _params, _current_user, _module, config) do
    redirect_to(conn, config.sign_in_return_path)
  end

  def delete(conn, _params, nil, _module, config) do
    redirect_to(conn, config.sign_out_return_path)
  end

  def delete(conn, _params, _current_user, module, config) do
    conn
    |> Haytni.logout(module)
    |> redirect_to(config.sign_out_return_path)
  end
end
