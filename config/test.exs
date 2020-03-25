use Mix.Config

config :haytni,
  ecto_repos: [HaytniTest.Repo]

config :logger,
  level: :error

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

config :haytni, HaytniTestWeb.Haytni,
  layout: false,
  repo: HaytniTest.Repo,
  schema: HaytniTest.User,
  mailer: HaytniTest.Mailer

config :haytni, HaytniTestWeb.Haytni2,
  layout: false,
  scope: :admin,
  repo: HaytniTest.Repo,
  schema: HaytniTest.Admin,
  mailer: HaytniTest.Mailer

config :haytni, HaytniTest.Mailer,
  adapter: Bamboo.TestAdapter
