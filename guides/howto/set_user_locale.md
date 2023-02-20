# How to set user's locale

## General setup

The first step would be to write a migration (`mix ecto.gen.migration user_locale_field`) to add a field to your table in order to store users's locale and, if you want to, also its timezone:

```elixir
# priv/repo/migrations/`date '+%Y%m%d%H%M%S'`_user_locale_field.ex

defmodule YourApp.Repo.Migrations.UserLocaleField do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :locale, :string
      add :timezone, :string # remove or comment if you don't need it
    end
  end
end
```

Then apply the very same migration by the `mix ecto.migrate` command.

Next, you also need to define these field in your user schema by adding the following `Ecto.Schema.field/3`:

```elixir
# lib/your_app/user.ex

defmodule YourApp.User do
  # ...

  schema "users" do
    # ...
    field :locale, :string
    field :timezone, :string
  end

  # ...
end
```

Now let's write a custom plug to set the appropriate locale for translations:

```elixir
# lib/your_app_web/plugs/set_user_locale.ex

defmodule YourAppWeb.SetUserLocalePlug do
  import Plug.Conn

  @supported_locales Gettext.known_locales(YourAppWeb.Gettext)

  @behaviour Plug

  @impl Plug
  def init(_opts), do: nil

  @impl Plug
  def call(conn = %Plug.Conn{assigns: %{current_user: %YourApp.User{locale: locale}}}, _options)
    when locale in @supported_locales
  do
    Gettext.put_locale(locale)
    conn
  end

  def call(conn, _options) do
    conn
  end
end
```

Add it to your `:browser` pipeline in your router but **after** calling your Haytni stack (the `plug YourApp.Haytni` line):

```elixir
# lib/your_app_web/router.ex

# ...
  pipeline :browser do
    # ...
    plug YourApp.Haytni
    plug YourAppWeb.SetUserLocalePlug # <= line to add
  end
# ...
```

For live views, you can globally achieve the same by implementing an `on_mount/4` callback:

```elixir
# your_app/lib/your_app_web/live/locale_on_mount_locale.ex

defmodule YourAppWeb.OnMount.Locale do
  @supported_locales Gettext.known_locales(YourAppWeb.Gettext)

  def on_mount(_, _params, _session, socket = %Phoenix.LiveView.Socket{assigns: %{current_user: %YourApp.User{locale: locale}}})
    when locale in @supported_locales
  do
    Gettext.put_locale(locale)
    {:cont, socket}
  end

  def on_mount(_, _params, _session, socket) do
    {:cont, socket}
  end
end
```

Then add it to your `Phoenix.LiveView.Router.live_session/3` block in your router, but **after** `YourAppWeb.Haytni` as follows:

```elixir
# app/your_app/lib/your_app_web/router.ex

  live_session(
    ...,
    on_mount: [
      # ...
      YourAppWeb.Haytni,
      YourAppWeb.OnMount.Locale, # <= **AFTER** YourAppWeb.Haytni
      # ...
    ]
  ) do
    # ...
  end
```

## Profile edition

It could be more useful if user can actually change its locale but we haven't taking care of this for now so let's remedy this.

We will begin by completing the template for editing registration:

Phoenix < 1.7:

```eex
# lib/your_app_web/templates/haytni/registration/edit.html.heex (global) or lib/your_app_web/templates/haytni/user/registration/edit.html.heex (scoped)

  <div>
    <%= label f, :locale, YourAppWeb.Gettext.dgettext("your_domain", "Locale") %>
    <%= select f, :locale, Gettext.known_locales(YourAppWeb.Gettext) %>
    <%= error_tag f, :locale %>
  </div>
  <div>
    <%= label f, :timezone, YourAppWeb.Gettext.dgettext("your_domain", "Timezone") %>
    <%= select f, :timezone, Tzdata.zone_lists_grouped() %>
    <%= error_tag f, :timezone %>
  </div>
```

Phoenix >= 1.7:

```eex
# lib/your_app_web/controllers/haytni/registration_html/edit.html.heex (global) or lib/your_app_web/controllers/haytni/user/registration_html/edit.html.heex (scoped)

  <.input
    field={{f, :locale}}
    type="select"
    label={YourAppWeb.Gettext.dgettext("your_domain", "Locale")}
    options={Gettext.known_locales(YourAppWeb.Gettext)}
  />
  <.input
    field={{f, :timezone}}
    type="select"
    label={YourAppWeb.Gettext.dgettext("your_domain", "Timezone")}
    options={Tzdata.zone_lists_grouped()}
  />
```

**Note**: to support timezones, you'll need [tzdata](https://hex.pm/packages/tzdata). To do so:

* add tzdata by the tuple `{:tzdata, "~> 1.1"}` in the `deps/0` function of your mix.exs file
* add `config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase` in config/config.exs

Finally, accept and validate those fields from the `update_registration_changeset/2` function in the user schema:

```elixir
# lib/your_app/user.ex

  # function to add (only to support user's timezone)
  defp validate_timezone(%Ecto.Changeset{} = changeset, field)
    when is_atom(field)
  do
    validate_change changeset, field, {:inclusion, nil}, fn _, value ->
      if Tzdata.zone_exists?(value) do
        []
      else
        [{field, {"is invalid", [validation: :inclusion]}}]
      end
    end
  end

  def update_registration_changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, ~W[locale timezone]a) # <= line to change
    |> validate_inclusion(:locale, Gettext.known_locales(YourAppWeb.Gettext)) # <= line to add
    |> validate_timezone(:timezone) # <= line to add (only needed for user to have a timezone)
    |> YourApp.Haytni.validate_update_registration()
  end
```

## Bonus : translating dates

Start by adding `:ex_cldr_dates_times` as a dependency to your project (function `deps/0` in your mix.exs file):

```elixir
# mix.exs

  {:ex_cldr_dates_times, "~> 2.0"},
```

Configure, through config/config.exs the default locale and timezone as you want (french here):

```elixir
# config/config.exs

config :your_app,
  default_locale: "fr",
  default_timezone: "Europe/Paris"
```

Create a module for Cldr:

```elixir
# lib/your_app/cldr.ex

defmodule YourApp.Cldr do
  use Cldr,
    locales: Gettext.known_locales(YourAppWeb.Gettext),
    providers: [
      Cldr.Number,
      Cldr.Calendar,
      Cldr.DateTime,
    ]
end
```

Now, you can run `mix deps.get` and restart your application.

In a global (= imported everywhere via the function `view/0` or `view_helpers/0` of lib/your_app_web.ex) view add the following `l/2` function:

```elixir
  defp do_l(dt = %DateTime{}, timezone, locale) do
    dt
    |> DateTime.shift_zone!(timezone)
    |> YourApp.Cldr.DateTime.to_string!(format: :long, locale: locale)
  end

  def l(dt = %DateTime{}, user = %User{}) do
    do_l(dt, user.timezone, user.locale)
  end

  def l(dt = %DateTime{}, nil) do
    do_l(dt, Application.fetch_env!(:your_app, :default_timezone), Application.fetch_env!(:your_app, :default_locale))
  end
```

Example of uses (in a template):

```
<%= l(~U[2018-07-16 10:00:00Z], @current_user) %>

<%= l(@post.created_at, @current_user) %>
```
