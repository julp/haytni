## Installation

The package can be installed by adding `haytni` to your list of dependencies in mix.exs:

```elixir
def deps do
  [
    # ...
    {:haytni, "~> 0.6.0"},
    {:ecto_network, "~> 1.3.0"}, # for TrackablePlugin only with PostgreSQL
  ]
end
```

Then run `mix deps.get`.

Configure Haytni *your_app*/config/config.exs

```elixir
config :haytni, YourApp.Haytni,
  #layout: {YourAppWeb.LayoutView, :app},
  #mailer: YourApp.Mailer, # see below
  otp_app: :your_app,
  repo: YourApp.Repo,
  schema: YourApp.User
```

For testing, you may also want to add the following settings to *your_app*/config/test.exs :

```elixir
config :bcrypt_elixir,
  log_rounds: 4

config :your_app, YourApp.Mailer,
  adapter: Bamboo.TestAdapter
```

These are the mandatory options. See options of each plugin for full customizations.

Run `mix haytni.install` which has the following options (command arguments):

  * `--table <table>` (default: `"users"`): the name of your table (used to generate migrations)
  * `--plugin Module1 --plugin Module2 ... --plugin ModuleN`: the names of the (Elixir) modules/plugins to enable

Create *your_app*/lib/*your_app*_web/haytni.ex :

```elixir
defmodule YourApp.Haytni do
  use Haytni, otp_app: :your_app

  stack Haytni.AuthenticablePlugin
  stack Haytni.RegisterablePlugin
  stack Haytni.RememberablePlugin, remember_salt: "a random string"
  stack Haytni.ConfirmablePlugin
  stack Haytni.LockablePlugin
  stack Haytni.RecoverablePlugin
  #stack Haytni.TrackablePlugin
  # add or remove/comment any plugin
end
```

Change *your_app*/lib/*your_app*_web/router.ex

```elixir
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  require YourApp.Haytni # <= add this line

  # ...

  pipeline :browser do
    # ...

    plug YourApp.Haytni # <= add this line
  end

  scope "/" do
    # ...

    YourApp.Haytni.routes() # <= add this line
  end

  # ...

end
```

Change *your_app*/lib/*your_app*/user.ex

```elixir
defmodule YourApp.User do
  require YourApp.Haytni # <= add this line

  # ...

  schema "..." do
    # ...

    YourApp.Haytni.fields() # <= add this line
  end

  @attributes ~W[email password]a
  def create_registration_changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, @attributes)
    |> YourApp.Haytni.validate_password()
    # ... (your custom validations) ...
    |> YourApp.Haytni.validate_create_registration()
  end

  @attributes ~W[email password current_password]a
  def update_registration_changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, @attributes)
    # ... (your custom validations) ...
    |> YourApp.Haytni.validate_update_registration()
  end

  # ...

end
```

## Emails

For plugins which send emails (Confirmable, Lockable and Recoverable):

Create *your_app*/lib/mailer.ex as follows:

```elixir
defmodule YourApp.Mailer do
  use Bamboo.Mailer, otp_app: :your_app

  def from, do: {"mydomain.com", "noreply.mydomain.com"}
end
```

Add to *your_app*/lib/*your_app*_web/router.ex

```elixir
  if Mix.env() == :dev do
    Application.ensure_started(:bamboo)

    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end
```

Configure email sending in *your_app*/config/dev.exs:

```elixir
config :your_app, YourApp.Mailer,
  adapter: Bamboo.LocalAdapter

config :haytni, YourApp.Haytni,
  mailer: YourApp.Mailer # <= add/change this line
```

For production (*your_app*/config/prod.exs), if you pass by your own SMTP server:

```elixir
config :your_app, YourApp.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "localhost", # the SMTP server is on the same host
  hostname: "www.domain.com",
  port: 25,
  tls: :never,
  no_mx_lookups: false,
  auth: :never
```

And add `{:bamboo_smtp, "~> 4.0", only: :prod}` to `deps` in your mix.exs file. [See Bamboo's documentation for details and other methods to send emails](https://hexdocs.pm/bamboo/readme.html)

General configuration:

* `layout` (default: `false` for none): the layout to apply to Haytni's templates

## Quick recap

Functions you have to implement:

* for Registerable: *YourApp.User*.create_registration_changeset/2 and *YourApp.User*.update_registration_changeset/2
* for sending emails (plugins Confirmable, Lockable and Recoverable): *YourApp*.Mailer.from/0
