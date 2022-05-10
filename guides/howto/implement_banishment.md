# How to implement banishment

Create a migration (`mix ecto.gen.migration user_banned_field`) to add a boolean field to your table:

```elixir
# priv/repo/migrations/`date '+%Y%m%d%H%M%S'`_user_banned_field.ex

defmodule YourApp.Repo.Migrations.UserBannedField do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :banned, :boolean, null: false
    end
  end
end
```

Then write a plugin which implements the `fields/1` to inject the *banned* column we created earlier and `invalid?/3` callback to return an error:

```elixir
# lib/your_app/haytni/ban_plugin.ex

defmodule YourApp.BanPlugin do
  use Haytni.Plugin
  #import YourApp.Gettext

  @impl Haytni.Plugin
  def fields(_module) do
    quote do
      field :banned, :boolean, default: false
    end
  end

  @impl Haytni.Plugin
  def invalid?(%_{banned: false}, _module, _config), do: false
  def invalid?(%_{}, _module, _config), do: {:error, "your account has been banned"} # better if you translate it with (d)gettext
end
```

Finally add `YourApp.BanPlugin` to your Haytni stack key in lib/*your_app*/haytni.ex:

```elixir
# lib/your_app/haytni.ex

defmodule YourApp.Haytni do
  use Haytni, otp_app: :your_app

  # ...

  stack YourApp.BanPlugin
end
```

(the part to turn it on or off in your admin panel is not shown - it's just a form/checkbox with a separate *changeset* function)
