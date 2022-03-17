## Installation

The package can be installed by adding `haytni` to your list of dependencies in mix.exs:

```elixir
def deps do
  [
    # ...
    {:haytni, "~> 0.6.3"},
    # with bcrypt support (for past and/or present passwords)
    {:expassword_bcrypt, "~> 0.2"},
    # with argon2 support (for past and/or present passwords)
    #{:expassword_argon2, "~> 0.2"},
    {:ecto_network, "~> 1.3.0"}, # for TrackablePlugin only with PostgreSQL
  ]
end
```

Then run `mix deps.get`.

Configure Haytni config/config.exs

```elixir
config :haytni, YourApp.Haytni,
  #layout: {YourAppWeb.LayoutView, :app},
  #mailer: YourApp.Mailer, # see below
  otp_app: :your_app,
  repo: YourApp.Repo,
  schema: YourApp.User
```

For testing, you may also want to add the following settings to config/test.exs :

```elixir
config :your_app, YourApp.Mailer,
  adapter: Bamboo.TestAdapter
```

These are the mandatory options. See options of each plugin for full customizations.

Run `mix haytni.install` which has the following options (command arguments):

  * `--table <table>` (default: `"users"`): the name of your table (used to generate migrations)
  * `--plugin Module1 --plugin Module2 ... --plugin ModuleN`: the names of the (Elixir) modules/plugins to enable

Create lib/*your_app*_web/haytni.ex :

```elixir
defmodule YourApp.Haytni do
  use Haytni, otp_app: :your_app

  # with bcrypt to hash current passwords
  stack Haytni.AuthenticablePlugin, hashing_method: ExPassword.Bcrypt, hashing_options: %{cost: (if Mix.env() == :test, do: 4, else: 10)}
  # with argon2 to hash current passwords
  #stack Haytni.AuthenticablePlugin, hashing_method: ExPassword.Argon2, hashing_options: (if Mix.env() == :test, do: %{memory_cost: 256, threads: 1, time_cost: 2, type: :argon2id}, else: %{memory_cost: 131072, threads: 2, time_cost: 4, type: :argon2id})
  stack Haytni.RegisterablePlugin
  stack Haytni.RememberablePlugin
  stack Haytni.ConfirmablePlugin
  stack Haytni.LockablePlugin
  stack Haytni.RecoverablePlugin
  #stack Haytni.TrackablePlugin
  stack Haytni.ClearSiteDataPlugin
  # add or remove/comment any plugin
end
```

Change lib/*your_app*_web/router.ex

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

If you use Phoenix LiveView, you can include your Haytni stack as an `on_mount` callback to also handle the current user:

```elixir
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  require YourApp.Haytni # <= add this line

  pipeline :browser do
    # ...

    plug YourApp.Haytni # <= add this line
  end

  live_session(
    ...,
    on_mount: [
      YourApp.Haytni, # <= add this line
      # your other on_mount callbacks
    ]
  ) do
    # your dead and live routes
    YourApp.Haytni.routes() # <= add this line
  end

  # ...

end
```

Note: `YourApp.Haytni.on_mount/4`, like `YourApp.Haytni.call/2` (acting as a Plug), just set the current user (if he is valid according to `c:Haytni.Plugin.invalid?/3`), if you need to restrict access, you need to do it after (with an other Plug or directly in the controller for a dead view vs a following `on_mount/4` callback or by the live view itself)

Change lib/*your_app*/user.ex

```elixir
defmodule YourApp.User do
  require YourApp.Haytni # <= add this line

  # ...

  schema "..." do
    # ...

    YourApp.Haytni.fields() # <= add this line
  end

  def create_registration_changeset(struct = %__MODULE__{}, params = %{}) do
    struct
    # add any needed field by registration from your own fields in the list below
    |> Ecto.Changeset.cast(params, [:email, :password])
    |> YourApp.Haytni.validate_password()
    # ... (your custom validations) ...
    |> YourApp.Haytni.validate_create_registration()
  end

  def update_registration_changeset(struct = %__MODULE__{}, params = %{}) do
    struct
    # put the names of the fields the user is allowed to change himself in the following empty list
    # but don't mention :email nor :password here, they are specifically handled by Haytni
    |> Ecto.Changeset.cast(params, [])
    # ... (your custom validations) ...
    |> YourApp.Haytni.validate_update_registration()
  end

  # ...

end
```

## Emails

For plugins which send emails (Confirmable, Lockable and Recoverable):

Create lib/mailer.ex as follows:

```elixir
defmodule YourApp.Mailer do
  use Bamboo.Mailer, otp_app: :your_app

  def from, do: {"mydomain.com", "noreply.mydomain.com"}
end
```

Add to lib/*your_app*_web/router.ex

```elixir
  if Mix.env() == :dev do
    Application.ensure_started(:bamboo)

    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end
```

Configure email sending in config/dev.exs:

```elixir
config :your_app, YourApp.Mailer,
  adapter: Bamboo.LocalAdapter

config :haytni, YourApp.Haytni,
  mailer: YourApp.Mailer # <= add/change this line
```

For production (config/prod.exs), if you pass by your own SMTP server:

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

And add `{:bamboo_smtp, "~> 4.1", only: :prod}` to `deps` in your mix.exs file. [See Bamboo's documentation for details and other methods to send emails](https://hexdocs.pm/bamboo/readme.html)

General configuration:

* `layout` (default: `false` for none): the layout to apply to Haytni's templates

## Quick recap

Functions you have to implement:

* for Registerable: *YourApp.User*.create_registration_changeset/2 and *YourApp.User*.update_registration_changeset/2
* for sending emails (plugins Confirmable, Lockable and Recoverable): *YourApp*.Mailer.from/0
