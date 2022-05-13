# How to restrict access to users based on their roles

## Single role (a user has only one role)

First, write a migration (`mix ecto.gen.migration user_role_table`) to create the *roles* table and add a foreign key to it to the *users* table:

```elixir
# priv/repo/migrations/`date '+%Y%m%d%H%M%S'`_user_role_table.exs

defmodule YourApp.Repo.Migrations.UserRoleTable do
  use Ecto.Migration

  def change do
    roles_table = "roles"

    create table(roles_table) do
      add :name, :string, null: false
    end

    create unique_index(roles_table, ~W[name]a)

    alter table("users") do
      add :role_id, references(roles_table, on_delete: :delete_all, on_update: :update_all), null: true
    end
  end
end
```

Apply it by running `mix ecto.migrate` or go back to your application and click the button "Run migrations for repo".

Create a module and schema for the roles:

```elixir
# lib/your_app/role.ex

defmodule YourApp.Role do
  use Ecto.Schema

  schema "roles" do
    field :name, :string

    has_many :users, YourApp.User
  end

  @required ~W[name]a
  @attributes @required ++ ~W[]a
  def changeset(struct = %__MODULE__{}, attrs = %{}) do
    struct
    |> Ecto.Changeset.cast(attrs, @attributes)
    |> Ecto.Changeset.validate_required(@required)
  end
end
```

Then, in your User schema, set the relationship from users to roles:

```elixir
# lib/your_app/user.ex

defmodule YourApp.User do
  # ...

  schema "users" do
    # ...
    belongs_to :role, YourApp.Role # <= line to add
  end

  # ...
end
```

Now, modify your Haytni stack to override the default `c:Haytni.Callbacks.user_query/1` callback in order to get the role preloaded along with the current user:

```elixir
# lib/your_app_web/haytni.ex

  @impl Haytni.Callbacks
  def user_query(query) do
    import Ecto.Query

    # with expressions
    # query
    # |> preload([:role])
    # with keywords
    from(
      # u in query, # with positional binding
      [{:user, u}] in query, # with named binding
      preload: [:role]
    )
  end
```

Database wise, everything is setup, let's restrict the access by writing a Plug receiving, as *options*, a list of the roles to let pass through:

```elixir
# lib/your_app_web/plugs/role_restricted_plug.ex

defmodule YourAppWeb.RoleRestrictedPlug do
  @behaviour Plug

  @impl Plug
  def init(roles) do
    roles
    |> List.wrap()
    |> Enum.map(&to_string/1)
  end

  @impl Plug
  def call(conn = %Plug.Conn{assigns: %{current_user: current_user}}, permitted_roles) do
    if has_role?(current_user, permitted_roles) do
      conn
    else
      conn
      |> Phoenix.Controller.put_flash(:error, "Restricted access") # better if you translate it with (d)gettext
      |> Phoenix.Controller.redirect(to: "/")
      |> Plug.Conn.halt()
    end
  end

  @spec has_role?(current_user :: YourApp.User.t | nil, _permitted_roles :: nonempty_list(String.t)) :: boolean
  defp has_role?(%YourApp.User{role: %YourApp.Role{name: user_role}}, permitted_roles) do
    user_role in permitted_roles
  end

  if Mix.env() == :dev do
    defp has_role?(%YourApp.User{role: association = %Ecto.Association.NotLoaded{}}, _permitted_roles) do
      raise ArgumentError, """
      The #{inspect(association.__field__)} association from #{inspect(association.__owner__)} module was not loaded,
      make sure your Haytni stack has redefined the user_query/1 callback to load it.
      """
    end
  end

  defp has_role?(_user, _permitted_roles), do: false
end
```

Here is an example on how to integrate it into your router: there are 2 new pipelines, the first *restricted_to_admin* to only allow users with "admin" role and the second, *restricted_to_foo_and_bar*, the users with either the role "foo" or "bar". But `pipeline` is only declarative, you have, then, to add it to `pipe_through` to the scope wrappring the routes you really want to protect:

```elixir
# lib/your_app_web/router.ex

# ...

  pipeline :browser do
    # ...
    plug YourApp.Haytni # <= your Haytni stack still has to be "globally" set
  end

  pipeline :restricted_to_admin do
    plug YourAppWeb.RoleRestrictedPlug, "admin"
  end

  pipeline :restricted_to_foo_and_bar do
    plug YourAppWeb.RoleRestrictedPlug, ~W[foo bar]
  end

  #live_session(
  #  :admin, # NOTE: this name doesn't matter, it isn't inherited by the :on_mount option
  #  on_mount: [
  #    YourApp.Haytni, # NOTE: YourApp.Haytni is equivalent to {YourApp.Haytni, :default}
  #    {YourAppWeb.OnMount, :admin}, # <= the most important line (with YourAppWeb.OnMount **after** YourApp.Haytni)
  #  ]
  #) do
    scope ... do
      pipe_through ~W[browser restricted_to_admin]a # <= the most important line (with :restricted_to_admin **after** :browser)

      # your restricted routes to "admin" role
    end
  #end

  #live_session(
  #  :foo_and_bar,
  #  on_mount: [
  #    YourApp.Haytni,
  #    {YourAppWeb.OnMount, :foo_and_bar}, # <= the most important line (with YourAppWeb.OnMount **after** YourApp.Haytni)
  #  ]
  #) do
    scope ... do
      pipe_through ~W[browser restricted_to_foo_and_bar]a # <= the most important line (with :restricted_to_foo_and_bar **after** :browser)

      # your restricted routes to roles "foo" and (exclusive) "bar"
    end
  #end

# ...
```

If you use LiveView, uncomment the `live_session` blocks and the `on_mount/4` callback can be written as follows, similar to our previous Plug:

```elixir
# lib/your_app_web/live/on_mount.ex

defmodule YourAppWeb.OnMount do
  import Phoenix.LiveView
  alias YourAppWeb.Router.Helpers, as: Routes

  defp do_check_role(_socket = %Phoenix.LiveView.Socket{assigns: %{current_user: %YourApp.User{role: %YourApp.Role{name: user_role}}}}, permitted_roles), do: user_role in permitted_roles
  defp do_check_role(_socket, _permitted_roles), do: false

  @spec check_role(socket :: Phoenix.LiveView.Socket.t, roles :: nonempty_list(String.t) | String.t | atom) :: {:cont | :halt, Phoenix.LiveView.Socket.t}
  defp check_role(socket, roles) do
    if do_check_role(socket, roles |> List.wrap() |> Enum.map(&to_string/1)) do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: Routes.haytni_user_session_path(socket, :new))}
    end
  end
  
  def on_mount(:admin, _params, _session, socket) do
    socket
    |> check_role("admin")
  end

  def on_mount(:foo_and_bar, _params, _session, socket) do
    socket
    |> check_role(~W[foo bar])
  end
end
```

## Multiple roles (a user can have several roles)

This a variant of the previous part where a user is not limited to a single role. Even if you are not concerned by the previous chapter, you should consider reading it for details about implementation since the present chapter will go straight to it.

We will start by a migration (`mix ecto.gen.migration user_roles_table`) to create a *roles* table and the intermediate association between *users* and *roles* named *users_roles*:

```elixir
# priv/repo/migrations/`date '+%Y%m%d%H%M%S'`_user_roles_table.exs

defmodule YourApp.Repo.Migrations.UserRolesTable do
  use Ecto.Migration

  def change do
    roles_table = "roles"
    association_table = "users_roles"

    create table(roles_table) do
      add :name, :string, null: false
    end

    create unique_index(roles_table, ~W[name]a)

    create table(association_table) do
      add :user_id, references("users", on_delete: :delete_all, on_update: :update_all), null: false
      add :role_id, references(roles_table, on_delete: :delete_all, on_update: :update_all), null: false
    end

    create unique_index(association_table, ~W[user_id role_id]a)
  end
end
```

From the user's schema declare a many to many association to *roles* by adding a `many_to_many` instruction:

```elixir
# lib/your_app/user.ex

defmodule YourApp.User do
  # ...

  schema "users" do
    # ...
    many_to_many :roles, YourApp.Role, join_through: "users_roles", on_replace: :delete # <= line to add
  end

  # ...
end
```

Then create the *role* schema:

```elixir
# lib/your_app/role.ex

defmodule YourApp.Role do
  use Ecto.Schema

  schema "roles" do
    field :name, :string

    many_to_many :users, YourApp.User, join_through: "users_roles"
  end

  @required ~W[name]a
  @attributes @required ++ ~W[]a
  def changeset(struct = %__MODULE__{}, attrs = %{}) do
    struct
    |> Ecto.Changeset.cast(attrs, @attributes)
    |> Ecto.Changeset.validate_required(@required)
  end
end
```

In our Haytni stack, we define the `c:Haytni.Callbacks.user_query/1` to compose the query in order to preload the user's roles:

```elixir
# lib/your_app_web/haytni.ex

  @impl Haytni.Callbacks
  def user_query(query) do
    import Ecto.Query

    query
    |> preload([:roles])
  end
```

The Plug is similar to the previous section, our `has_role?` function just requires some adjustments to handle the collection of roles.

```elixir
# lib/your_app_web/plugs/role_restricted_plug.ex

defmodule YourAppWeb.RoleRestrictedPlug do
  @behaviour Plug

  @impl Plug
  def init(roles) do
    roles
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> MapSet.new()
  end

  @impl Plug
  def call(conn = %Plug.Conn{assigns: %{current_user: current_user}}, permitted_roles) do
    if has_role?(current_user, permitted_roles) do
      conn
    else
      conn
      |> Phoenix.Controller.put_flash(:error, "Restricted access") # better if you translate it with (d)gettext
      |> Phoenix.Controller.redirect(to: "/")
      |> Plug.Conn.halt()
    end
  end

  @spec has_role?(current_user :: YourApp.User.t | nil, _permitted_roles :: MapSet.t(String.t)) :: boolean
  defp has_role?(nil, _permitted_roles), do: false

  defp has_role?(%YourApp.User{roles: user_roles}, permitted_roles)
    when is_list(user_roles)
  do
    user_roles
    |> Enum.map(&(&1.name))
    |> MapSet.new()
    |> MapSet.disjoint?(permitted_roles)
    |> Kernel.not()
  end

  if Mix.env() == :dev do
    defp has_role?(%YourApp.User{roles: association = %Ecto.Association.NotLoaded{}}, _permitted_roles) do
      raise ArgumentError, """
      The #{inspect(association.__field__)} association from #{inspect(association.__owner__)} module was not loaded,
      make sure your Haytni stack has redefined the user_query/1 callback to load it.
      """
    end
  end
end
```

Its use, in the router, doesn't change.

If you use LiveView, our previous `do_check_role` function requires a change in the same way than the Plug:

```elixir
# lib/your_app_web/live/on_mount.ex

defmodule YourAppWeb.OnMount do
  import Phoenix.LiveView
  alias YourAppWeb.Router.Helpers, as: Routes

  defp do_check_role(_socket = %Phoenix.LiveView.Socket{assigns: %{current_user: %YourApp.User{roles: user_roles}}}, permitted_roles)
    when is_list(user_roles)
  do
    pr =
      permitted_roles
      |> List.wrap()
      |> Enum.map(&to_string/1)
      |> MapSet.new()

    user_roles
    |> Enum.map(&(&1.name))
    |> MapSet.new()
    |> MapSet.disjoint?(pr)
    |> Kernel.not()
  end

  defp do_check_role(_socket, _permitted_roles), do: false

  @spec check_role(socket :: Phoenix.LiveView.Socket.t, roles :: nonempty_list(String.t) | String.t | atom) :: {:cont | :halt, Phoenix.LiveView.Socket.t}
  defp check_role(socket, roles) do
    if do_check_role(socket, roles |> List.wrap() |> Enum.map(&to_string/1)) do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: Routes.haytni_user_session_path(socket, :new))}
    end
  end
  
  def on_mount(:admin, _params, _session, socket) do
    socket
    |> check_role("admin")
  end

  def on_mount(:foo_and_bar, _params, _session, socket) do
    socket
    |> check_role(~W[foo bar])
  end
end
```
