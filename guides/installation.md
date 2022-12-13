## Installation

The package can be installed by adding `haytni` to your list of dependencies in mix.exs:

```elixir
def deps do
  [
    # ...
    {:haytni, "~> 0.7.0"},
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

These are the mandatory options. See options of each plugin for full customizations.

Run `mix haytni.install` which has the following options (command arguments):

  * `--table <table>` (default: `"users"`): the name of your table (used to generate migrations)
  * `--plugin Module1 --plugin Module2 ... --plugin ModuleN`: the names of the (Elixir) modules/plugins to enable

Create lib/*your_app*_web/haytni.ex :

```elixir
defmodule YourApp.Haytni.Helpers do
  def expassword_options(:test, algo = ExPassword.Bcrypt), do: [hashing_method: algo, hashing_options: %{cost: 4}]
  def expassword_options(_env, algo = ExPassword.Bcrypt), do: [hashing_method: algo, hashing_options: %{cost: 10}]

  def expassword_options(:test, algo = ExPassword.Argon2), do: [hashing_method: algo, hashing_options: %{memory_cost: 256, version: 0x13, threads: 1, time_cost: 2, type: :argon2id}]
  def expassword_options(_env, algo = ExPassword.Argon2), do: [hashing_method: algo, hashing_options: %{memory_cost: 131072, version: 0x13, threads: 2, time_cost: 4, type: :argon2id}]
end

defmodule YourApp.Haytni do
  use Haytni, otp_app: :your_app
  import YourApp.Haytni.Helpers

  # with bcrypt to hash current passwords
  stack Haytni.AuthenticablePlugin, expassword_options(Mix.env(), ExPassword.Bcrypt)
  # with argon2 to hash current passwords
  #stack Haytni.AuthenticablePlugin, expassword_options(Mix.env(), ExPassword.Argon2)
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

This is only required by plugins which send emails (as of right now: Confirmable, Lockable, Recoverable and Invitable plugins) else Haytni's `:mailer` option can be omitted or set to `nil`.

### Clients

#### Bamboo

If not already done, add `:bamboo` as dependency to `deps/0` of your mix.exs file:

```elixir
# mix.exs

  defp deps do
    [
      # ...
      {:bamboo, "~> 2.2"}, # (check https://hex.pm for latest version)
      # ...
    ]
  end
```

Create lib/*your_app*/mailer.ex as follows:

```elixir
# lib/your_app/mailer.ex

defmodule YourApp.Mailer do
  use Haytni.Mailer, [
    otp_app: :my_app,
    adapter: Haytni.Mailer.BambooAdapter,
  ]

  @impl Haytni.Mailer
  def from, do: {"mydomain.com", "noreply@mydomain.com"}
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
  mailer: YourApp.Mailer
```

For testing, you may also want to add the following settings to config/test.exs :

```elixir
config :your_app, YourApp.Mailer,
  adapter: Bamboo.TestAdapter
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

#### Swoosh

First add Swoosh to your dependencies in `deps/0` in your mix.exs file:

```elixir
# mix.exs

  defp deps do
    [
      # ...
      {:swoosh, "~> 1.8"}, # (check https://hex.pm for latest version)
      # ...
    ]
  end
```

Then create lib/*your_app*/mailer.ex like below:

```elixir
# lib/your_app/mailer.ex

defmodule YourApp.Mailer do
  use Haytni.Mailer, [
    otp_app: :my_app,
    adapter: Haytni.Mailer.SwooshAdapter,
  ]

  @impl Haytni.Mailer
  def from, do: {"mydomain.com", "noreply@mydomain.com"}
end
```

Optional, add to lib/*your_app*_web/router.ex to consult mails on dev environment:

```elixir
  if Mix.env() == :dev do
    forward "/mailbox", Plug.Swoosh.MailboxPreview
  end
```

Configure email sending in config/dev.exs:

```elixir
config :your_app, YourApp.Mailer,
  adapter: Swoosh.Adapters.Local

config :haytni, YourApp.Haytni,
  mailer: YourApp.Mailer
```

For tests (config/test.exs) you'll need to setup the adapter Swoosh comes with:

```elixir
config :your_app, YourApp.Mailer,
  adapter: Swoosh.Adapters.Local
```

On the opposite, for production (config/prod.exs) you'll want to disabled the memory storage process by:

```elixir
config :swoosh, local: false
```

And add the specific adapter that fits your needs.

#### Other

To support any other client, you need to implement the `Haytni.Mailer.Adapter` behaviour:

```elixir
# lib/your_app/mailer.ex

defmodule YourApp.Mailer do
  use Haytni.Mailer.Adapter

  @impl Haytni.Mailer
  def from, do: {"mydomain.com", "noreply@mydomain.com"}

  @impl Haytni.Mailer.Adapter
  def cast(email = %Haytni.Mail{}, mailer, _options) do
    # ...
  end

  @impl Haytni.Mailer.Adapter
  def send(email = %{__struct__: Bamboo.Email}, mailer, options) do
    # ...
  end
end
```

(any pull request to handle any other client is welcome)

### Delivery strategies

#### Immediate (synchronous)

You should probably avoid this since sending an email can takes some time, blocking the user/HTTP request meanwhile. If you really want to adopt this behaviour, set `strategy: Haytni.Mailer.ImmediateDeliveryStrategy` in lib/your_app/mailer.ex:

```elixir
# lib/your_app/mailer.ex

defmodule YourApp.Mailer do
  use Haytni.Mailer.Adapter, [
    opt_app: ...,
    adapter: ...,
    strategy: Haytni.Mailer.ImmediateDeliveryStrategy,
  ]

  # ...
end
```

#### Unsupervised (asynchronous) (default)

This is the default strategy used by Haytni: the email is sent in a background process (`Task`), meaning the client has not to wait after the email has been sent. But this is done in an unsupervised way: if the operation [sending the email] fails, you won't know it and neither won't be retried later. Since this is the default delivery method, you can omit the `:strategy` option in lib/your_app/mailer.ex or set it explicitely to `Haytni.Mailer.UnsupervisedTaskStrategy`.

#### Supervised (asynchronous)

TODO

```
# lib/your_app/mailer.ex

defmodule YourApp.Mailer do
  use Haytni.Mailer.Adapter, [
    opt_app: ...,
    adapter: ...,
    strategy: Haytni.Mailer.TaskSupervisorStrategy,
  ]

  # ...
end
```

#### Other

You can come with your own delivery strategy by implemenenting the `Haytni.Mailer.DeliveryStrategy` behaviour.

In particular, if emails are more critical, you can send them through Oban, a service broker, ...

## Quick recap

Functions you have to implement:

* for Registerable: *YourApp.User*.create_registration_changeset/2 and *YourApp.User*.update_registration_changeset/2
* for sending emails (plugins Confirmable, Lockable and Recoverable): *YourApp*.Mailer.from/0
