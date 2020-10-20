defmodule Haytni.LiveViewPlugin do
  @default_token_path "/token"
  @token_path_key :token_path

  #@default_token_validity {12, :second}
  #@default_socket_id &default_socket_id/1

  @moduledoc """
  TODO

  Configuration:

    * TODO

  Routes: TODO
  """

  defmodule Config do
    defstruct remote_ip_header: nil,
      token_validity: {2, :minute}, # {12, :second},
      socket_id: &Haytni.LiveViewPlugin.default_socket_id/1

    @type t :: %__MODULE__{
      remote_ip_header: String.t | nil,
      token_validity: Haytni.duration,
      socket_id: (Haytni.user -> String.t),
    }
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %Haytni.LiveViewPlugin.Config{}
    |> Haytni.Helpers.merge_config(options, ~W[token_validity]a)
  end

  @impl Haytni.Plugin
  def routes(prefix_name, options) do
    prefix_name = :"#{prefix_name}_token"
    token_path = Keyword.get(options, @token_path_key, @default_token_path)
    quote bind_quoted: [prefix_name: prefix_name, token_path: token_path] do
      resources token_path, HaytniWeb.Tokenable.TokenController, singleton: true, only: ~W[create]a, as: prefix_name
    end
  end

  def default_socket_id(user = %_{}) do
    "user_socket:#{user.id}"
  end

  @spec token_context() :: String.t
  def token_context do
    "channel+live_view"
  end

  @impl Haytni.Plugin
  def on_logout(conn = %Plug.Conn{}, module, config) do
    #if _live_socket_id = get_session(conn, :live_socket_id) do
      IO.inspect(config.socket_id)
      conn.assigns[:"current_#{module.scope()}"]
      |> config.socket_id.()
      |> module.endpoint().broadcast("disconnect", %{})
    #end
    conn
  end

  # TODO: à déplacer dans config ? (sinon c'est commun à toutes les stacks)
  @separator "/"
  @algorithm "AES128GCM"
  @key :crypto.strong_rand_bytes(32) # (re)generated at compile time
  @pepper :crypto.strong_rand_bytes(24)

  defp encrypt(content) do
    iv = :crypto.strong_rand_bytes(32)
    {ct, tag} = :crypto.block_encrypt(:aes_gcm, @key, iv, {@algorithm, content})
    Base.encode16(iv <> tag <> ct)
  end

  defp decrypt(payload) do
    with(
      {:ok, <<iv::binary-32, tag::binary-16, ct::binary>>} <- Base.decode16(payload),
      data when data != :error <- :crypto.block_decrypt(:aes_gcm, @key, iv, {@algorithm, ct, tag})
    ) do
      {:ok, data}
    else
      _ ->
        :error
    end
  end

  defp digest(content) do
    content
    |> :erlang.md5()
    |> Base.encode16()
  end

  @spec encode_token(conn :: Plug.Conn.t, token :: Haytni.token) :: String.t
  def encode_token(conn = %Plug.Conn{}, token) do
    content =
      [@pepper, %{"ip" => conn.remote_ip |> :inet_parse.ntoa() |> to_string(), "token" => Haytni.Token.encode_token(token)} |> Phoenix.json_library().encode!()]
      |> Enum.join(@separator)
    hash =
      content
      |> digest()
    [content, hash]
    |> Enum.join(@separator)
    |> encrypt()
  end

  @spec decode_token(token_param :: String.t) :: {:ok, %{required(String.t) => String.t}} | :error
  def decode_token(token_param) do
    with(
      {:ok, data} when is_binary(data) <- decrypt(token_param),
      [@pepper, challenge, hash] <- String.split(data, @separator),
      ^hash <- [@pepper, challenge] |> Enum.join(@separator) |> digest(),
      v = {:ok, _data} <- Phoenix.json_library().decode(challenge)
    ) do
      v
    else
      _ ->
        :error
    end
  end

  @doc ~S"""
  TODO: destiné à être appelé depuis la callback connect (channels)
  """
  @spec connect(module :: module, params :: map, socket :: Phoenix.Socket.t, connect_info :: map) :: {:ok, Phoenix.Socket.t} | :error
  def connect(module, params, socket, connect_info) do
    config = module.fetch_config(__MODULE__)
    remote_ip_as_string = if is_nil(config.remote_ip_header) do
      connect_info.peer_data.address
      |> :inet_parse.ntoa()
      |> to_string()
    else
      key = config.remote_ip_header
      case :lists.keyfind(key, 1, connect_info.x_headers) do
        {^key, value} -> value
        false -> :key_not_found
      end
    end
    with(
      token when not is_nil(token) <- Map.get(params, "token"),
      {:ok, %{"ip" => ^remote_ip_as_string, "token" => token}} <- decode_token(token),
      {:ok, token} <- Haytni.Token.decode_token(token),
      user when not is_nil(user) <- Haytni.Token.user_from_token_with_mail_match(module, token, token_context(), config.token_validity)
      # TODO: vérifier que user est valide
    ) do
      {:ok, Phoenix.Socket.assign(socket, :"current_#{module.scope()}", user)} # TODO: Phoenix.LiveView.assign pour live view ?
    else
      _ ->
        :error
    end
  end

  #@doc ~S"""
  #TODO: destiné à être appelé depuis la callback mount (live view)
  #"""
  #def mount_user(module, params, _session, socket) do
    # TODO: on a accès à la session ?
    # params sont les mount_params qui sont différents des connect_params ? => Phoenix.LiveView.get_connect_params(socket)
    #case connect(module, params, socket, Phoenix.LiveView.get_connect_info(socket) do
      #
    #end
  #end
end
