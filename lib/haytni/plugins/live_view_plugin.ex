defmodule Haytni.LiveViewPlugin do
  @default_token_path "/token"
  @token_path_key :token_path

  @default_remote_ip_header nil
  @default_token_validity {2, :minute}
  @default_socket_id nil

  @moduledoc """
  This module "replace" the *_csrf_token* generated by Phoenix, if you can't use it (mainly because of caching), to recognize the current authenticated user in channels
  and, by extension, live view since access to session through websocket rely on this *_csrf_token*. To do so, this module provides a controller to deliver short lived
  ciphered and signed token which you request in Javascript (ajax is the main way) and send it back to the server for the websocket connection. Then, Haytni will set
  the current user for the websocket when you call `connect/4` from your `c:Phoenix.Socket.connect/3` callback (channels) and `mount_user/4` from your
  `c:Phoenix.LiveView.mount/3` (live view).

  Configuration:

    * `remote_ip_header` (default: `#{inspect(@default_remote_ip_header)}`): if a proxy in front of phoenix follows you the IP address of the client through a specific
      header, explicit it here. For example, with nginx configured with `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;`, set `remote_ip_header: "x-forwarded-for"`
    * `token_validity` (default: `#{inspect(@default_token_validity)}`): duration of generated token. You should keep it as short as possible (not more than few minutes)
      since these tokens are intended to be used right after they were requested
    * `socket_id` (default: `#{inspect(@default_socket_id)}`): a function to resolve a user into a socket's name. This function, from a module (your Haytni's stack) and a user,
      should return a string (binary) that identify a socket, the same value returned by your `c:Phoenix.Socket.id/1` callback

          stack #{inspect(__MODULE__)},
            socket_id: #{inspect(@default_socket_id)},
            token_validity: #{inspect(@default_token_validity)}
            remote_ip_header: #{inspect(@default_remote_ip_header)},

  Routes: `haytni_<scope>_token_path` (action: create): default path is `#{inspect(@default_token_path)}` but you can override it by the
    `#{inspect(@token_path_key)}` option when calling YourApp.Haytni.routes/1 from your router
  """

  defmodule Config do
    defstruct socket_id: nil,
      remote_ip_header: nil,
      token_validity: {2, :minute},
      separator: "/",
      algorithm: "AES128GCM",
      # a default key generated at compile time for all stacks
      key: :crypto.strong_rand_bytes(32),
      # a default pepper generated at compile time for all stacks
      pepper: :crypto.strong_rand_bytes(24)

    @type t :: %__MODULE__{
      key: binary,
      pepper: binary,
      algorithm: String.t,
      separator: String.t,
      remote_ip_header: String.t | nil,
      token_validity: Haytni.duration,
      socket_id: (module, Haytni.user -> String.t)
    }
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    options =
      options
      |> Enum.into(%{})
      # key generated once, at runtime, specific to the current stack
      |> Map.put_new_lazy(:key, fn -> :crypto.strong_rand_bytes(32) end)
      # pepper generated once, at runtime, specific to the current stack
      |> Map.put_new_lazy(:pepper, fn -> :crypto.strong_rand_bytes(24) end)

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

  defp default_socket_id(module, user = %_{}) do
    "#{module.scope()}_socket:#{user.id}"
  end

  @spec token_context() :: String.t
  def token_context do
    "channel+live_view"
  end

  @impl Haytni.Plugin
  def on_logout(conn = %Plug.Conn{}, module, config) do
    socket_id = config.socket_id || &default_socket_id/2
    user = conn.assigns[:"current_#{module.scope()}"] # TODO: provide user to on_logout callbacks?

    module
    |> socket_id.(user)
    |> module.endpoint().broadcast("disconnect", %{})
    conn
  end

  defp encrypt(content, config) do
    iv = :crypto.strong_rand_bytes(32)
    {ct, tag} = :crypto.block_encrypt(:aes_gcm, config.key, iv, {config.algorithm, content})
    Base.encode16(iv <> tag <> ct)
  end

  defp decrypt(payload, config) do
    with(
      {:ok, <<iv::binary-32, tag::binary-16, ct::binary>>} <- Base.decode16(payload),
      data when data != :error <- :crypto.block_decrypt(:aes_gcm, config.key, iv, {config.algorithm, ct, tag})
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

  @doc ~S"""
  Add metadata (IP address) to *token* then hash and cipher the whole.
  """
  @spec encode_token(conn :: Plug.Conn.t, token :: Haytni.Token.t, config :: Config.t) :: String.t
  def encode_token(conn = %Plug.Conn{}, token, config) do
    content =
      [
        config.pepper,
        %{
          "ip" => conn.remote_ip |> :inet_parse.ntoa() |> to_string(),
          "token" => Haytni.Token.encode_token(token)
        }
        |> Phoenix.json_library().encode!()
      ]
      |> Enum.join(config.separator)

    hash =
      content
      |> digest()

    [
      content,
      hash,
    ]
    |> Enum.join(config.separator)
    |> encrypt(config)
  end

  @doc ~S"""
  Extract metadata and real token from a previously "encoded" token by `encode_token/3`
  """
  @spec decode_token(config :: Config.t, token_param :: String.t) :: {:ok, %{required(String.t) => String.t}} | :error
  def decode_token(config, token_param) do
    pepper = config.pepper
    with(
      {:ok, data} when is_binary(data) <- decrypt(token_param, config),
      [^pepper, challenge, hash] <- String.split(data, config.separator),
      ^hash <- [config.pepper, challenge] |> Enum.join(config.separator) |> digest(),
      v = {:ok, _data} <- Phoenix.json_library().decode(challenge)
    ) do
      v
    else
      _ ->
        :error
    end
  end

  @spec connect(module :: module, config :: Config.t, params :: map, socket :: Phoenix.Socket.t, connect_info :: map) :: {:ok, Phoenix.Socket.t} | :error
  def connect(module, config, params, socket, connect_info) do
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
      {:ok, %{"ip" => ^remote_ip_as_string, "token" => token}} <- decode_token(config, token),
      {:ok, token} <- Haytni.Token.decode_token(token),
      user when not is_nil(user) <- Haytni.Token.user_from_token_with_mail_match(module, token, token_context(), config.token_validity),
      false <- Haytni.invalid_user?(module, user)
    ) do
      {:ok, Phoenix.Socket.assign(socket, :"current_#{module.scope()}", user)} # TODO: Phoenix.LiveView.assign pour live view ? (retourner {:ok, :"current_#{module.scope()}", user} | :error  pour ensuite appeler la bonne fonction assign ?)
    else
      _ ->
        :error
    end
  end

  @doc ~S"""
  For channels, to be called in `c:Phoenix.Socket.connect/3` callback in order to set the current user
  in assigns (named `:current_user` by default - same way as it is done for Plug.Conn).

  Example:

      # lib/your_app_web/channels/user_socket.ex
      defmodule YourAppWeb.UserSocket do
        @impl Phoenix.Socket
        def connect(params, socket, connect_info) do
          Haytni.LiveViewPlugin.connect(YourApp.Haytni, params, socket, connect_info)
        end
      end
  """
  @spec connect(module :: module, params :: map, socket :: Phoenix.Socket.t, connect_info :: map) :: {:ok, Phoenix.Socket.t} | :error
  def connect(module, params, socket, connect_info) do
    config = module.fetch_config(__MODULE__)
    connect(module, config, params, socket, connect_info)
  end

  @doc ~S"""
  TODO: destiné à être appelé depuis la callback mount (live view)
  """
  def mount_user(module, params, _session, socket) do
    # params sont les mount_params qui sont différents des connect_params ? => Phoenix.LiveView.get_connect_params(socket)
    case connect(module, params, socket, Phoenix.LiveView.get_connect_info(socket)) do
      # TODO
      _ ->
        :error
    end
  end
end
