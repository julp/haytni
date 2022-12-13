defmodule Haytni.LiveView.ConnectTest do
  use HaytniWeb.ChannelCase, [
    async: true,
    plugin: Haytni.LiveViewPlugin,
  ]
  #alias HaytniTestWeb.UserSocket

  @ip {66, 249, 79, 35}

  defp ip_to_string(ip) do
    ip
    |> :inet_parse.ntoa()
    |> to_string()
  end

  describe "Haytni.LiveViewPlugin.connect/5" do
    setup do
      user =
        Haytni.ConfirmablePlugin.confirmed_attributes()
        |> user_fixture()

      {:ok, token} =
        user
        |> Haytni.Token.build_and_assoc_token(user.email, @plugin.token_context(nil))
        |> HaytniTest.Repo.insert()

      conn =
        Phoenix.ConnTest.build_conn()
        |> Map.replace!(:remote_ip, @ip)
        |> Map.replace!(:secret_key_base, @endpoint.config(:secret_key_base))
        |> Plug.Conn.put_private(:haytni, HaytniTestWeb.Haytni)
        |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)
      [
        conn: conn,
        user: user,
        token: token,
      ]
    end

    defp connect_info_from_config(%Haytni.LiveViewPlugin.Config{remote_ip_header: nil}) do
      %{
        peer_data: %{
          address: @ip,
        },
      }
    end

    defp connect_info_from_config(%Haytni.LiveViewPlugin.Config{remote_ip_header: foward_header}) do
      %{
        peer_data: %{
          address: {127, 0, 0, 1},
        },
        x_headers: [
          {foward_header, ip_to_string(@ip)},
          {foward_header, "1.2.3.4"}, # just to make sure only the first is considered
        ],
      }
    end

    defp do_connect(module, config = %Haytni.LiveViewPlugin.Config{}, token) do
      connect_info =
        config
        |> connect_info_from_config()

      @plugin.connect(module, config, %{"token" => token}, %Phoenix.Socket{}, connect_info)
    end

    test "socket authentication with valid token", %{conn: conn, user: user, token: token} do
      config = @plugin.build_config(remote_ip_header: nil)
      assert {:ok, socket} = do_connect(@stack, config, @plugin.encode_token(conn, token, config))
      assert socket.assigns.current_user.id == user.id

      for proxy_header <- ~W[x-forwarded-for x-proxyuser-ip] do
        config = @plugin.build_config(remote_ip_header: proxy_header)
        assert {:ok, socket} = do_connect(@stack, config, @plugin.encode_token(conn, token, config))
        assert socket.assigns.current_user.id == user.id
      end
    end

    test "socket authentication with invalid token", %{conn: conn, token: token} do
      config = @plugin.build_config(remote_ip_header: nil)
      token = @plugin.encode_token(conn, %{token | token: "not a match"}, config)
      {:ok, socket} = do_connect(@stack, config, token)
      assert is_nil(socket.assigns.current_user)
    end

    test "socket authentication with IP missmatch", %{conn: conn, token: token} do
      config = @plugin.build_config(remote_ip_header: nil)
      {:ok, socket} = do_connect(@stack, config, @plugin.encode_token(%{conn | remote_ip: {43, 72, 58, 56}}, token, config))
      assert is_nil(socket.assigns.current_user)
    end
  end
end
