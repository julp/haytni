defmodule HaytniTestWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :haytni

  @session_options [
    store: :cookie,
    key: "_haytni_test_key",
    signing_salt: "9wWymz8u",
  ]

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session, @session_options

  plug HaytniTestWeb.Router
end
