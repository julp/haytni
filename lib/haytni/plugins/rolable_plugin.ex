defmodule Haytni.RolablePlugin do
  @default_role_path "/role"

  @moduledoc """
  This module brings everything (schema/association, roles management, plug) you need to deal with roles.

  Fields: none but adds 2 tables (users_roles and users_roles__assoc)

  Configuration: none

  Routes: `haytni_<scope>_role_path` (default: `#{inspect(@default_role_path)}`) (action: new/create, edit/update, index, delete): the interface to manage roles

  In your Haytni stack, add:

  ```elixir
  stack #{inspect(__MODULE__)}
  ```

  To manage roles, add, in your router:

  ```elixir
  require Haytni.RolablePlugin

  Haytni.RolablePlugin.routes(YourAppWeb.Haytni)
  ```

  > #### Warning {: .warning}
  >
  > Make sure to properly restrict the access to these administrative routes. Example:
  >
  > ```elixir
  > defmodule YourAppWeb.Router do
  >   # ...
  >
  >   pipeline :restricted_to_admin do
  >     # put your restricting logic here (only applies to "dead views")
  >     plug YourAppWeb.AdminRestrictedPlug
  >   end
  >
  >   # <only with "live views">
  >   live_session(
  >     :admin, # NOTE: this name doesn't matter, it isn't inherited by the :on_mount option
  >     on_mount: [
  >       YourAppWeb.Haytni,
  >       {YourAppWeb.OnMount, :admin}, # <= the most important line (with YourAppWeb.OnMount **after** YourApp.Haytni)
  >     ]
  >   ) do
  >   # </only with "live views">
  >     scope ... do
  >       pipe_through [:browser, :restricted_to_admin] # <=
  >
  >       require Haytni.RolablePlugin
  >       Haytni.RolablePlugin.routes(YourAppWeb.Haytni)
  >    end
  >   # <only with "live views">
  >   )
  >   # </only with "live views">
  >
  >   # ...
  > end
  > ```
  >
  > For "dead views" you can implement `YourAppWeb.AdminRestrictedPlug` like the following:
  >
  > ```elixir
  > defmodule YourAppWeb.AdminRestrictedPlug do
  >   @behaviour Plug
  >
  >   @impl Plug
  >   def init(options) do
  >     options
  >   end
  >
  >   @impl Plug
  >   def call(conn, options) do
  >     # put your restricting logic here (only applies to "dead views")
  >     admin? = ...
  >
  >     if admin? do
  >       conn
  >     else
  >       conn
  >       |> Phoenix.Controller.put_flash(:error, "Restricted access") # better if you translate it with (d)gettext
  >       |> Phoenix.Controller.redirect(to: "/")
  >       |> Plug.Conn.halt()
  >     end
  >   end
  > end
  > ```
  >
  > Actually you can even use `HaytniWeb.RolablePlugin.RoleRestrictedPlug` instead of writing your own Plug but you'd need to disable it (from `pipe_through`) or issue a command to first add yourself the appropriate role.
  >
  > To do so, replace the following line in the router above:
  >
  > ```elixir
  > plug YourAppWeb.AdminRestrictedPlug
  > ```
  >
  > By (admitting your first created a role named "admin" and assigned it to yourself):
  >
  > ```elixir
  > plug HaytniWeb.RolablePlugin.RoleRestrictedPlug, "admin"
  > ```
  >
  > For "live views" you need to implement `YourAppWeb.OnMount.on_mount/3` as below:
  >
  > ```elixir
  > defmodule YourAppWeb.OnMount do
  >   import Phoenix.LiveView
  >   alias YourAppWeb.Router.Helpers, as: Routes
  >
  >   def on_mount(:admin, params, session, socket) do
  >     # put your restricting logic here (only applies to "live views")
  >     admin? = ...
  >
  >     if admin? do
  >       {:cont, socket}
  >     else
  >       {:halt, socket |> put_flash(:error, "Restricted access") |> redirect(to: "/")}
  >     end
  >   end
  > end
  > ```
  """

  @type role :: struct
  @type roles :: [role]

  use Haytni.Plugin

  @impl Haytni.Plugin
  def files_to_install(_base_path, web_path, scope, timestamp) do
    if Haytni.Helpers.phoenix17?() do
      [
        # HTML
        {:eex, "phx17/views/role_html.ex", Path.join([web_path, "controllers", "haytni", scope, "role_html.ex"])},
        {:eex, "phx17/templates/role/_form.html.heex", Path.join([web_path, "controllers", "haytni", scope, "role_html", "_form.html.heex"])},
        {:eex, "phx17/templates/role/new.html.heex", Path.join([web_path, "controllers", "haytni", scope, "role_html", "new.html.heex"])},
        {:eex, "phx17/templates/role/edit.html.heex", Path.join([web_path, "controllers", "haytni", scope, "role_html", "edit.html.heex"])},
        {:eex, "phx17/templates/role/index.html.heex", Path.join([web_path, "controllers", "haytni", scope, "role_html", "index.html.heex"])},
      ]
    # TODO: remove this when dropping support for Phoenix < 1.7
    else
      [
        # HTML
        {:eex, "phx16/views/role_view.ex", Path.join([web_path, "views", "haytni", scope, "role_view.ex"])},
        {:eex, "phx16/templates/role/_form.html.heex", Path.join([web_path, "templates", "haytni", scope, "role", "_form.html.heex"])},
        {:eex, "phx16/templates/role/new.html.heex", Path.join([web_path, "templates", "haytni", scope, "role", "new.html.heex"])},
        {:eex, "phx16/templates/role/edit.html.heex", Path.join([web_path, "templates", "haytni", scope, "role", "edit.html.heex"])},
        {:eex, "phx16/templates/role/index.html.heex", Path.join([web_path, "templates", "haytni", scope, "role", "index.html.heex"])},
      ]
    end ++ [
      # migration
      {:eex, "migrations/0-rolable_changes.exs", Path.join([web_path, "..", "..", "priv", "repo", "migrations", "#{timestamp}_haytni_rolable_#{scope}_changes.exs"])},
    ]
  end

  @roles_association_name :roles

  def __after_compile__(env, _bytecode) do
    contents = quote do
      use Ecto.Schema
      import Ecto.Changeset

      schema unquote("#{env.module.__schema__(:source)}_roles") do
        field :name, :string

        many_to_many unquote(env.module |> Phoenix.Naming.resource_name() |> String.to_atom()), unquote(env.module), [
          on_replace: :delete,
          join_through: unquote("#{env.module.__schema__(:source)}_roles__assoc"),
          join_keys: [
            role_id: :id,
            user_id: :id, # :"#{scope}_id" ?
          ]
        ]
      end

      @required ~W[name]a
      @attributes ~W[]a ++ @required
      def changeset(struct = %__MODULE__{}, params \\ %{}) do
        struct
        |> cast(params, @attributes)
        |> validate_required(@required)
        |> unique_constraint(:name)
      end
    end

    Module.create(env.module.__schema__(:association, @roles_association_name).related, contents, env)
  end

  @impl Haytni.Plugin
  def fields(_module) do
    quote do
      @after_compile Haytni.RolablePlugin

      many_to_many unquote(@roles_association_name), Haytni.Helpers.scope_module(__MODULE__, "Role"), [
        on_replace: :delete,
        join_through: "#{@ecto_struct_fields[:__meta__].source}_roles__assoc",
        join_keys: [
          user_id: :id,
          role_id: :id,
        ]
      ]
    end
  end

  @doc ~S"""
  Adds management routes to the router.

  ```elixir
  require Haytni.RolablePlugin

  Haytni.RolablePlugin.routes(YourAppWeb.Haytni)
  # or
  Haytni.RolablePlugin.routes(YourAppWeb.Haytni, path: "/role")
  ```
  """
  defmacro routes(module, options \\ []) do
    role_path = Keyword.get(options, :path, @default_role_path)
    quote bind_quoted: [module: module, role_path: role_path] do
      scope "/", as: false, alias: false do
        resources role_path, HaytniWeb.Rolable.RoleController, [
          except: [:show],
          private: %{haytni: module},
          as: :"haytni_#{module.scope()}_role",
        ]
      end
    end
  end

  @impl Haytni.Plugin
  def user_query(query, _module, _config) do
    import Ecto.Query

    from(
      [{:user, user}] in query,
      left_join: roles in assoc(user, :roles),
        as: :roles,
      preload: [
        roles: roles,
      ]
      #select_merge: %{user | roles: roles.name}
    )
  end

  defp haytni_module_to_role_module(module) do
    module.schema().__schema__(:association, @roles_association_name).related
  end

  @spec roles_base_query(module :: module) :: Ecto.Query.t
  defp roles_base_query(module) do
    import Ecto.Query

    role_module = haytni_module_to_role_module(module)
    from(
      role in role_module,
      order_by: [:name]
    )
  end

  @doc ~S"""
  Lists all available roles from a stack.
  """
  @spec list_roles(module :: module) :: roles
  def list_roles(module)
    when is_atom(module)
  do
    module
    |> roles_base_query()
    |> module.repo().all()
  end

  defp do_list_roles(_module, _only = []) do
    []
  end

  defp do_list_roles(module, only)
    when is_atom(module) and is_list(only)
  do
    import Ecto.Query

    query = module |> roles_base_query()

    from(
      role in query,
      where: role.id in ^only
    )
    |> module.repo().all()
  end

  @doc ~S"""
  Lists roles from a stack having their id in *only*.

  (used to preload user's role when editing it)
  """
  @spec list_roles(module :: module, only :: [String.t]) :: roles
  def list_roles(module, only)
    when is_atom(module)
    and is_list(only)
  do
    do_list_roles(module, only)
  end

  @doc ~S"""
  Retrieves a *role* from a stack and its id, raises if no such role (id) exists.

  ```elixir
  role = get_role!(YourAppWeb.Haytni, id)
  ```
  """
  @spec get_role!(module :: module, id :: String.t) :: role | no_return
  def get_role!(module, id) do
    module.repo().get!(haytni_module_to_role_module(module), id)
  end

  @doc ~S"""
  Creates an `t:Ecto.Changeset.t` from a stack or role.

  ```elixir
  def new(conn, _params) do
    conn
    |> assign(:changeset, change_role(YourAppWeb.Haytni))
    |> render(:new)
  end

  def edit(conn, _params = %{"id" => id}) do
    role = get_role!(YourAppWeb.Haytni, id)

    conn
    |> assign(:changeset, change_role(role))
    |> render(:edit)
  end
  ```
  """
  @spec change_role(module_or_role :: module | role) :: Ecto.Changeset.t
  def change_role(module)
    when is_atom(module)
  do
    module
    |> haytni_module_to_role_module()
    |> struct()
    |> change_role()
  end

  def change_role(role)
    when is_struct(role)
  do
    role.__struct__.changeset(role, %{})
  end

  @doc ~S"""
  Creates a new *role*.

  ```elixir
  def create(conn, _params = %{"role" => role_params}) do
    case create_role(YourAppWeb.Haytni, role_params) do
      {:ok, role} ->
        # ...
      {:error, changeset} ->
        # ...
    end
  end
  ```
  """
  @spec create_role(module :: module, params :: Haytni.params) :: Haytni.repo_nobang_operation(role)
  def create_role(module, params) do
    role =
      module
      |> haytni_module_to_role_module()
      |> struct()

    role
    |> role.__struct__.changeset(params)
    |> module.repo().insert()
  end

  @doc ~S"""
  Updates the given *role*.

  ```elixir
  def update(conn, _params = %{"role" => role_params}) do
    role = get_role!(YourAppWeb.Haytni, id)
    case update_role(YourAppWeb.Haytni, role_params, role) do
      {:ok, updated_role} ->
        # ...
      {:error, changeset} ->
        # ...
    end
  end
  ```
  """
  @spec update_role(module :: module, params :: Haytni.params, role :: role) :: Haytni.repo_nobang_operation(role)
  def update_role(module, params, role) do
    role
    |> role.__struct__.changeset(params)
    |> module.repo().update()
  end

  @doc ~S"""
  Deletes the given *role*.

  ```elixir
  def delete(conn, _params = %{"id" => id}) do
    role = get_role!(YourAppWeb.Haytni, id)
    {:ok, _role} = delete_role(YourAppWeb.Haytni, role)

    # ...
  end
  ```
  """
  @spec delete_role(module :: module, role :: role) :: Haytni.repo_nobang_operation(role)
  def delete_role(module, role)
    when is_struct(role)
  do
    module.repo().delete(role)
  end

  @doc ~S"""
  Checks if *current_user* has **at least one** of *required_roles*

      iex> has_role?(nil, MapSet.new(["ADMIN"]))
      false

      iex> has_role?(%User{roles: [%UserRole{name: "ROLE_A"}, %UserRole{name: "ROLE_B"}, %UserRole{name: "ROLE_C"}]}, MapSet.new(~W[ROLE_B ROLE_D]))
      true
  """
  @spec has_role?(current_user :: Haytni.nilable(Haytni.user), required_roles :: MapSet.t(String.t)) :: boolean
  def has_role?(nil, _required_roles), do: false

  def has_role?(%_{@roles_association_name => user_roles}, required_roles)
    when is_list(user_roles)
  do
    # OR
    user_roles
    |> Enum.map(&(&1.name))
    |> MapSet.new()
    |> MapSet.disjoint?(required_roles)
    |> Kernel.not()

    # AND
#     required_roles
#     |> MapSet.subset?(user_roles |> Enum.map(&(&1.name)) |> MapSet.new())
  end

  def has_role?(%_{@roles_association_name => association = %Ecto.Association.NotLoaded{}}, _required_roles) do
    require Logger

    Logger.warning(
      fn ->
        """
        The #{inspect(association.__field__)} association from #{inspect(association.__owner__)} module was not loaded,
        make sure your Haytni stack has redefined the user_query/1 callback to load it.
        """
      end
    )

    false
  end
end
