# How to implement banishment

Create a migration to add a boolean field to your table:

priv/repo/migrations/\`date '+%Y%m%d%H%m%s'\`_add_banned_field.ex
```elixir
defmodule YourApp.AddBannedField do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :banned, :boolean, null: false
    end
  end
end
```

lib/your_app/ban_plugin.ex
```elixir
defmodule YourApp.BanPlugin do
  use Haytni.Plugin
  #import YourApp.Gettext

  @impl Haytni.Plugin
  def fields do
    quote do
      field :banned, :boolean, default: false
    end
  end

  @impl Haytni.Plugin
  def invalid?(%_{banned: false}), do: false
  def invalid?(%_{}), do: {:error, "you are persona non grata"} # better if you translate it with (d)gettext
end
```

Finally add it to *plugins* key in config/config.exs:
```elixir
config :haytni,
  # ...
  plugins: [
    # ...
    YourApp.BanPlugin
  ],
```

(the part to turn it on or off in your admin panel is not shown - its just a form/checkbox with a separate *changeset* function)
