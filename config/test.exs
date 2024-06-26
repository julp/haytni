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
  port: 5433,
  username: "haytni",
  password: "haytni",
  hostname: "localhost",
  database: "haytni_test",
  socket_dir: "/tmp/",
  pool: Ecto.Adapters.SQL.Sandbox

config :haytni, HaytniTestWeb.Haytni,
  layout: false,
  repo: HaytniTest.Repo,
  schema: HaytniTest.User,
  mailer: HaytniTest.TestMailer

config :haytni, HaytniTestWeb.HaytniAdmin,
  layout: false,
  scope: :admin,
  repo: HaytniTest.Repo,
  schema: HaytniTest.Admin,
  mailer: HaytniTest.TestMailer

config :haytni, HaytniTestWeb.HaytniCustomRoutes,
  layout: false,
  scope: :cr,
  repo: HaytniTest.Repo,
  schema: HaytniTest.Admin,
  mailer: HaytniTest.TestMailer

config :haytni, HaytniTestWeb.HaytniEmpty,
  layout: false,
  scope: :empty,
  repo: HaytniTest.Repo,
  schema: HaytniTest.User,
  mailer: HaytniTest.TestMailer
