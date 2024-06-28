defmodule Haytni.SessionPlugin do
  @default_timeout_in {24, :minute}
  @last_activity_session_key :last_activity_at

  @moduledoc """
  TODO (doc)
  """

  use Haytni.Plugin

  defstruct [
    timeout_in: @default_timeout_in,
  ]

  @type t :: %__MODULE__{
    timeout_in: Haytni.nilable(pos_integer),
  }

  @impl Haytni.Plugin
  def build_config(options) do
    %__MODULE__{}
    |> Haytni.Helpers.merge_config(options, options[:timeout_in] && ~W[timeout_in]a || [])
  end

  defp now do
    DateTime.utc_now() |> DateTime.to_unix
  end

  defp put_activity_in_session(conn, _config = %__MODULE__{timeout_in: nil}) do
    conn
  end

  defp put_activity_in_session(conn, _config) do
    conn
    |> Plug.Conn.put_session(@last_activity_session_key, now())
  end

  defp do_find_user(conn, module, _config) do
    scoped_session_key = Haytni.scoped_session_key(module)

    conn
    |> Plug.Conn.get_session(scoped_session_key)
    |> case do
      nil ->
        {conn, nil}
      id ->
        {conn, Haytni.get_user(module, id)}
    end
  end

  @impl Haytni.Plugin
  def find_user(conn, module, config = %__MODULE__{timeout_in: nil}) do
    do_find_user(conn, module, config)
  end

  def find_user(conn, module, config) do
    with(
      last_activity_at <- Plug.Conn.get_session(conn, @last_activity_session_key),
      true <- is_integer(last_activity_at),
      true <- last_activity_at + config.timeout_in >= now()
    ) do
      conn
      |> put_activity_in_session(config)
      |> do_find_user(module, config)
    else
      _ ->
        {conn, nil}
    end
  end

  @impl Haytni.Plugin
  def on_logout(conn, module, _config, options) do
    scoped_session_key = Haytni.scoped_session_key(module)

    case Keyword.get(options, :scope) do
      :all ->
        conn
        |> Plug.Conn.clear_session()
        |> Plug.Conn.configure_session(drop: true)
      _ ->
        conn
        |> Plug.Conn.configure_session(renew: true)
        |> Plug.Conn.delete_session(scoped_session_key)
    end
  end

#   @impl Haytni.Plugin
#   def on_failed_authentication(_user, multi, keywords, _module, _config) do
#     # TODO: supprimer la session ? (mais implique d'avoir conn)
#     {multi, keywords}
#   end

  @impl Haytni.Plugin
  def on_successful_authentication(conn, user, multi, keywords, module, _config) do
    scoped_session_key = Haytni.scoped_session_key(module)

    Plug.CSRFProtection.delete_csrf_token()
    conn =
      conn
#       |> put_activity_in_session(conn, config)
      |> Plug.Conn.put_session(scoped_session_key, user.id)
      |> Plug.Conn.configure_session(renew: true)

    {conn, multi, keywords}
  end
end
