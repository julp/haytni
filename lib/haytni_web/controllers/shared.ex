defmodule HaytniWeb.Shared do
  @moduledoc ~S"""
  Contains shared stuffs between Haytni base plugins.

  Mainly handle a message view/template which is intended to replace "abusive" `Phoenix.Controller.put_flash/3`.
  `put_flash` stores messages in session and may have several issues:

    * it can conflict if you use multiple tabs or instances of a same browser
    * excessive reads/writes (depending on the backend)
    * incompatible with HTTP caching
  """

  use HaytniWeb, :controller

  @doc ~S"""
  Returns the path to the login page.
  """
  @spec session_path(conn :: Plug.Conn.t, module :: module) :: String.t
  def session_path(conn, module) do
    apply(module.router(), :"haytni_#{module.scope()}_session_path", [conn, :new])
  end

  @doc ~S"""
  Momorize the original HTTP referer by adding it to a changeset. Have to be called on `new` or `edit` action
  (not `create` nor `update`).
  """
  @spec add_referer_to_changeset(conn :: Plug.Conn.t, changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  def add_referer_to_changeset(conn = %Plug.Conn{}, changeset = %Ecto.Changeset{}) do
    referer = with [referer] <- Plug.Conn.get_req_header(conn, "referer") do
      referer
    else
      _ ->
        nil
    end
    Ecto.Changeset.put_change(changeset, :referer, referer)
  end

  @doc ~S"""
  Add a back/cancel link for SharedView.

  NOTE: we do not use `"javascript:history.back()"` as default since this may be inappropriate with Content
  Security Policy (CSP). But user is free to use it by indicating it as value for *default*.
  """
  @spec back_link(conn :: Plug.Conn.t, struct :: struct, default :: String.t) :: Plug.Conn.t
  def back_link(conn = %Plug.Conn{}, struct = %_{}, default) do
    back_link = with(
      referer when not is_nil(referer) <- Map.get(struct, :referer),
      host = Keyword.get(Phoenix.Controller.endpoint_module(conn).config(:url), :host, "localhost"),
      %URI{host: ^host, scheme: scheme} when scheme in ~W[http https] <- URI.parse(referer)
    ) do
      referer
    else
      _ ->
        nil
    end || default || "/"
    conn
    |> assign(:back_link, back_link)
  end

  @doc ~S"""
  Add a next step link for SharedView.
  """
  @spec next_step_link(conn :: Plug.Conn.t, href :: String.t, text :: String.t) :: Plug.Conn.t
  def next_step_link(conn = %Plug.Conn{}, href, text) do
    conn
    |> assign(:next_step_link_text, text)
    |> assign(:next_step_link_href, href)
  end

  @doc ~S"""
  Set connection to render SharedView/message.html.
  """
  @spec render_message(conn :: Plug.Conn.t, module :: module, message :: String.t, type :: atom) :: Plug.Conn.t
  def render_message(conn = %Plug.Conn{}, module, message, type \\ :info) do
    conn
    |> assign(:type, type)
    |> assign(:message, message)
    |> HaytniWeb.Helpers.put_view(module, "SharedView")
    |> render("message.html")
  end
end
