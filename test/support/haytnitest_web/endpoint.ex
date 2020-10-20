defmodule HaytniTestWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :haytni

  @session_options [
    store: :cookie,
    key: "_haytni_test_key",
    signing_salt: "9wWymz8u",
  ]

  #socket "/socket", HaytniTestWeb.UserSocket,
    #websocket: [connect_info: [:peer_data, :x_headers]],
    #longpoll: false

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session, @session_options

  plug HaytniTestWeb.Router
end
