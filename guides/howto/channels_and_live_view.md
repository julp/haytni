# How to use with Channels or Live View?

First add `Haytni.LiveViewPlugin` to your Haytni stack in lib/*your_app*/haytni.ex by appending the following line:

```elixir
  stack Haytni.LiveViewPlugin
```

Then, in your endpoint (lib/your_app_web/endpoint.ex), you should find something like that:

```elixir
socket "/socket", YourAppWeb.UserSocket,
    websocket: true,
    longpoll: false
```

Make sure to change the `true` values here to `[connect_info: [:peer_data, :x_headers]]`.

TODO (call from connect/3 callback)

```elixir
# lib/your_app_web/channels/user_socket.ex
defmodule YourAppWeb.UserSocket do
  @impl Phoenix.Socket
  def connect(params, socket, connect_info) do
    Haytni.LiveViewPlugin.connect(YourApp.Haytni, params, socket, connect_info)
  end

  # ...
end
```

Now, in your javascript asset file, to acquire a token and reinject it to be granted to create a connection, use something like the following:

```javascript
fetch(
    '/token', {
        method: 'POST',
        headers: {
            'Accept': 'application/json',
        },
    }
)
.then(
    response => response.json()
).then(
    token => {
        let socket = new Socket("/socket", {transport: WebSocket, params: {token: token}})
        socket.connect()
        /* ... */
    }
)
```

`fetch` above can be replaced by a regular Ajax (XMLHttpRequest) call if your prefer.

`'/token'` is the value of `Routes.haytni_<scope>_token_path/[23]` if you do a mix `phx.routes`. This path can be overriden by the `:token_path` key when you call `YourApp.Haytni.routes/1` in your router.

## Configuration

### If Phoenix is behind nginx or any proxy

Tokens for channels and liveview are short lived and validated against current IP address. But IP addresses from *peer_data* might be wrong if Phoenix does not directly handles HTTP and sockets. If this is your case, you need to specify the name (in lower case!) of the HTTP header your *proxy* follows you client addresses as `:remote_ip_header` option of `stack Haytni.LiveViewPlugin`.

For example, if you use nginx and it is configured with:

```nginx
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

So you have to write:

```elixir
stack Haytni.LiveViewPlugin, remote_ip_header: "x-forwarded-for"
```

### Proper disconnection of channels and Live View

For proper logout to channels and live view, you need to write the `c:Phoenix.Socket.id/1` callback and, if last one does not return the string `"user_socket:#{socket.assigns.current_<scope>.id}"`, you'll need to write a function somewhere and give it (via capture) as `:socket_id` option. Let's see an example:

```elixir
# lib/your_app_web/channels/user_socket.ex
defmodule YourAppWeb.UserSocket do
  use Phoenix.Socket

  # ...

  @impl Phoenix.Socket
  def id(socket) do
    "user_socket:#{socket.assigns.current_user.id}"
  end
end
```

```elixir
  stack Haytni.LiveViewPlugin, socket_id: &("user_socket:#{&1.id}")
```
