# How to delete a user

Haytni does not directly handle account deletion (account removal) because everyone might want to do it in very different ways:

* delay it to give some time to the user to think about it and cancel it if wished
* confirm the action
* do some kind of soft-deletion instead
* remove extra data, even non-SQL
* ...

So, it has to be written as a plugin which implements the `c:Haytni.Plugin.on_delete_user/4` callback. Let's see some use cases as examples and guidelines.

## Hard deletion

To delete the user from the database (meaning issue a `DELETE` SQL statement), your `c:Haytni.Plugin.on_delete_user/4` callback just need to add a `Ecto.Multi.delete/4` operation to the `Ecto.Multi` received from its parameters :

```elixir
defmodule YourApp.HaytniPlugin do
  use Haytni.Plugin

  @impl Haytni.Plugin
  def on_delete_user(multi = %Ecto.Multi{}, user = %_{}, _module, _config) do
    multi
    |> Ecto.Multi.delete(:deletion, user)
  end
end
```

## Soft deletion

The idea is the same but instead of deleting the user, we update (`Ecto.Multi.update/4`) it to turn off some field and flag reflecting this state.

```elixir
defmodule YourApp.HaytniPlugin do
  use Haytni.Plugin

  @impl Haytni.Plugin
  def fields(_module) do
    quote do
      field :deleted, :boolean, default: true
    end
  end

  @impl Haytni.Plugin
  def invalid?(user = %_{}, _module, _config) do
    user.deleted && {:error, :deleted}
  end

  @impl Haytni.Plugin
  def on_delete_user(multi = %Ecto.Multi{}, user = %_{}, _module, _config) do
    multi
    |> Ecto.Multi.update(:deletion, Ecto.Changeset.change(user, [deleted: true]))
  end
end
```

The callbacks `c:Haytni.Plugin.fields/1` and `c:Haytni.Plugin.invalid?/3` were also implemented to deal with this additional information.

## Anonymize account

In this scenario, the idea is to issue an `UPDATE` to nullify (at least) the password and email.

```elixir
defmodule YourApp.HaytniPlugin do
  use Haytni.Plugin

  @impl Haytni.Plugin
  def on_delete_user(multi = %Ecto.Multi{}, user = %_{}, _module, _config) do
    multi
    |> Ecto.Multi.update(:deletion, Ecto.Changeset.change(user, [encrypted_password: nil, email: nil]))
  end
end
```

But don't forget to write a migration for encrypted_password and email to be nullable.
