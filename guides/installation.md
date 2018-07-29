# Installation

add haytni as dependency in your mix.exs

```elixir
def deps do
  [
    {:haytni, "~> 0.0.1"},
    # ...
  ]
end
```

Run `mix deps.get`.

Configure Haytni *your_app*/config/config.exs

```
config :haytni,
  repo: YourApp.Repo,
  schema: YourApp.User
```

These are the mandatory options. See options of each plugin for full customizations.

Run `mix haytni.install` which has the following options (command arguments):
* `--table <table>` (default: `"users"`): the name of your table (used to generate migrations)
* `--plugin Module1 --plugin Module2 ... --plugin ModuleN` (default: value of `config :haytni, plugins: [...]`): the names of the (Elixir) modules/plugins to enable

Change *your_app*/lib/*your_app*_web/router.ex

```elixir
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  require Haytni # <= add this line

  # ...

  pipeline :browser do
    # ...

    plug Haytni.CurrentUserPlug # <= add this line
  end

  scope "/" do
    # ...

    Haytni.routes() # <= add this line
  end

  # ...

end
```

Change *your_app*/lib/*your_app*/user.ex

```elixir
defmodule YouApp.User do
  require Haytni # <= add this line

  # ...

  schema "..." do
    # ...

    Haytni.fields() # <= add this line
  end

  # ...

end
```

## Emails

For plugins which send emails (confirmable, lockable, recoverable):

*your_app*/lib/*your_app*/mailer.ex
lib/mailer.ex

```elixir
defmodule YourApp.Mailer do
  use Bamboo.Mailer, otp_app: :your_app

  def from, do: {"xxx.com", "noreply.xxx.com"}
end
```

Add to *your_app*/lib/*your_app*_web/router.ex

```elixir
  if Mix.env == :dev do
    Application.ensure_started(:bamboo)
    if Version.compare(Application.spec(:bamboo, :vsn) |> to_string, "0.8.0") == :lt do
      # Bamboo > 0.8
      forward "/sent_emails", Bamboo.SentEmailViewerPlug
    else
      # Bamboo <= 0.8
      forward "/sent_emails", Bamboo.EmailPreviewPlug
    end
  end
```

Configure email sending:

*your_app*/config/dev.exs

```elixir
config :yourapp, YourApp.Mailer,
  adapter: Bamboo.LocalAdapter

config :haytni,
  mailer: YourApp.Mailer # <= add this line
```

*your_app*/config/prod.exs: [see Bamboo's documentation](https://hexdocs.pm/bamboo/readme.html)
