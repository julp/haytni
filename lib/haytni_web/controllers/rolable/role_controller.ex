defmodule HaytniWeb.Rolable.RoleController do
  @moduledoc false

  use HaytniWeb, :controller
  use HaytniWeb.Helpers, Haytni.RolablePlugin

  import Haytni.RolablePlugin

  plug :assign_role_paths

  defp assign_role_paths(conn, _options) do
    module = conn.private.haytni
    router_helpers_module = Module.concat([module.web_module(), :Router, :Helpers])
    path_function = :"haytni_#{module.scope()}_role_path"

    conn
    |> assign(:role_path_2, Function.capture(router_helpers_module, path_function, 2))
    |> assign(:role_path_3, Function.capture(router_helpers_module, path_function, 3))
  end

  defp redirect_to_index(conn) do
    conn
    |> redirect(to: conn.assigns.role_path_2.(conn, :index))
    |> halt()
  end

  def index(conn, _params, module, _config) do
    conn
    |> assign(:roles, list_roles(module))
    |> render(:index)
  end

  def show(conn, _params = %{"id" => id}, module, _config) do
    role = get_role!(module, id)

    conn
    |> assign(:role, role)
    |> render(:show)
  end

  defp render_new(conn = %Plug.Conn{}, changeset = %Ecto.Changeset{}) do
    conn
    |> assign(:changeset, changeset)
    |> render(:new)
  end

  def new(conn, _params, module, _config) do
    render_new(conn, change_role(module))
  end

  def create(conn, _params = %{"role" => role_params}, module, _config) do
    module
    |> create_role(role_params)
    |> case do
      {:ok, _role} ->
        redirect_to_index(conn)
      {:error, changeset = %Ecto.Changeset{}} ->
        render_new(conn, changeset)
    end
  end

  defp render_edit(conn = %Plug.Conn{}, changeset = %Ecto.Changeset{}, role) do
    conn
    |> assign(:role, role)
    |> assign(:changeset, changeset)
    |> render(:edit)
  end

  def edit(conn, _params = %{"id" => id}, module, _config) do
    role = get_role!(module, id)

    render_edit(conn, change_role(role), role)
  end

  def update(conn, _params = %{"id" => id, "role" => role_params}, module, _config) do
    role = get_role!(module, id)

    module
    |> update_role(role_params, role)
    |> case do
      {:ok, _role} ->
        redirect_to_index(conn)
      {:error, changeset = %Ecto.Changeset{}} ->
        render_edit(conn, changeset, role)
    end
  end

  def delete(conn, _params = %{"id" => id}, module, _config) do
    role = get_role!(module, id)
    delete_role(module, role)

    redirect_to_index(conn)
  end
end
