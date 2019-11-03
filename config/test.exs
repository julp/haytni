import Config

config :bcrypt_elixir,
  log_rounds: 4

config :haytni, HaytniTestWeb.Endpoint,
  http: [port: 4001],
  secret_key_base: "s1heawGXF5+zpOvg+mrGJoKQhQ4kVMNLSgW+TShHIDqisLiwd2Wqjf478JZR3xXv",
  server: false

config :haytni, HaytniTest.Repo,
  username: "haytni",
  password: "haytni",
  database: "haytni_test",
  hostname: "localhost",
  socket_dir: "/tmp/",
  pool: Ecto.Adapters.SQL.Sandbox

config :haytni,
  otp_app: :haytni_test,
  repo: HaytniTest.Repo,
  schema: HaytniTest.User,
  mailer: HaytniTest.Mailer

config :haytni, HaytniTest.Mailer,
  adapter: Bamboo.TestAdapter
