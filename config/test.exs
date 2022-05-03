import Config

config :haytni,
  ecto_repos: [HaytniTest.Repo]

config :logger,
  level: :error

config :haytni, HaytniTestWeb.Endpoint,
  http: [port: 4001],
  pubsub_server: HaytniTest.PubSub,
  secret_key_base: "s1heawGXF5+zpOvg+mrGJoKQhQ4kVMNLSgW+TShHIDqisLiwd2Wqjf478JZR3xXv",
  server: false

config :haytni, HaytniTest.Repo,
  username: "haytni",
  password: "haytni",
  database: "haytni_test",
  socket_dir: "/tmp/",
  pool: Ecto.Adapters.SQL.Sandbox

config :haytni, HaytniTestWeb.Haytni,
  layout: false,
  repo: HaytniTest.Repo,
  schema: HaytniTest.User,
  mailer: HaytniTest.Mailer

config :haytni, HaytniTestWeb.HaytniAdmin,
  layout: false,
  scope: :admin,
  repo: HaytniTest.Repo,
  schema: HaytniTest.Admin,
  mailer: HaytniTest.Mailer

config :haytni, HaytniTestWeb.HaytniCustomRoutes,
  layout: false,
  scope: :cr,
  repo: HaytniTest.Repo,
  schema: HaytniTest.Admin,
  mailer: HaytniTest.Mailer

config :haytni, HaytniTestWeb.HaytniEmpty,
  layout: false,
  scope: :empty,
  repo: HaytniTest.Repo,
  schema: HaytniTest.User,
  mailer: HaytniTest.Mailer

config :haytni, HaytniTest.Mailer,
  adapter: Bamboo.TestAdapter
