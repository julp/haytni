defmodule HaytniTestWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :haytni

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_haytni_test_key",
    signing_salt: "9wWymz8u"

  plug HaytniTestWeb.Router
end
