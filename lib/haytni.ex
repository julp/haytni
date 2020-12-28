defmodule Haytni do
  @moduledoc ~S"""
  Documentation for Haytni.
  """

  @application :haytni

  @type user :: struct
  @type config :: any
  @type irrelevant :: any
  @type duration_unit :: :second | :minute | :hour | :day | :week | :month | :year
  @type duration :: pos_integer | {pos_integer, duration_unit}

  @type nilable(type) :: type | nil
  @type params :: %{optional(String.t) => String.t}
  @type repo_nobang_operation(type) :: {:ok, type} | {:error, Ecto.Changeset.t}
  @type multi_result :: {:ok, %{required(Ecto.Multi.name) => any}} | {:error, Ecto.Multi.name, any, %{optional(Ecto.Multi.name) => any}}

  @spec app_base(atom | module) :: String.t
  defp app_base(app) do
    case Application.get_env(app, :namespace, app) do
      ^app ->
        app
        |> to_string()
        |> Phoenix.Naming.camelize()
      mod ->
        mod
        |> inspect()
    end
  end

  defp fetch_env!(key) do
    Application.fetch_env!(@application, key)
  end

  defmacro __using__(options) do
    otp_app = Keyword.fetch!(options, :otp_app)

    web_module = otp_app
    |> app_base()
    |> Kernel.<>("Web")
    |> String.to_atom()

    quote do
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :plugins, accumulate: true)

      @behaviour Plug
      @before_compile unquote(__MODULE__)

      @spec otp_app() :: atom
      def otp_app do
        unquote(otp_app)
      end

      @spec web_module() :: atom
      def web_module do
        unquote(web_module)
      end

      @spec router() :: module
      def router do
        unquote(Module.concat([web_module, :Router, :Helpers]))
      end

      @spec endpoint() :: module
      def endpoint do
        unquote(Module.concat([web_module, :Endpoint]))
      end

      @spec schema() :: module
      def schema do
        unquote(fetch_env!(__CALLER__.module)[:schema])
      end

      @spec repo() :: module
      def repo do
        unquote(fetch_env!(__CALLER__.module)[:repo])
      end

      @spec mailer() :: module
      def mailer do
        unquote(fetch_env!(__CALLER__.module)[:mailer])
      end

      @spec layout() :: false | {module, atom}
      def layout do
        unquote(Keyword.get(fetch_env!(__CALLER__.module), :layout, false))
      end

      @spec scope() :: atom
      def scope do
        unquote(Keyword.get(fetch_env!(__CALLER__.module), :scope, :user))
      end

      @impl Plug
      def init(_options), do: nil

      @impl Plug
      def call(conn, _options) do
        scope = :"current_#{scope()}"
        if Map.get(conn.assigns, scope) do
          conn
        else
          {conn, user} = Haytni.find_user(__MODULE__, conn)
          Plug.Conn.assign(conn, scope, user)
        end
        |> Plug.Conn.put_private(:haytni, __MODULE__)
      end

      defmacro routes(options \\ []) do
        unquote(__MODULE__).routes(__MODULE__, options)
      end

      defmacro fields do
        unquote(__MODULE__).fields(__MODULE__)
      end

      #def plugin_enabled?(module) do
      #def create_user(attrs = %{}, options \\ []) do
      #def update_registration(user = %_{}, attrs = %{}, options \\ []) do
      #def authentication_failed(user = nil) do
      #def authentication_failed(user = %_{}) do
      #def update_user_with(user = %_{}, changes) do
      #def update_user_with!(user = %_{}, changes) do

      def validate_create_registration(changeset) do
        unquote(__MODULE__).validate_create_registration(__MODULE__, changeset)
      end

      def validate_update_registration(changeset) do
        unquote(__MODULE__).validate_update_registration(__MODULE__, changeset)
      end

      def validate_password(changeset) do
        unquote(__MODULE__).validate_password(__MODULE__, changeset)
      end
    end
  end

  defmacro stack(module, options \\ []) do
    quote do
      Module.put_attribute(__MODULE__, :plugins, {unquote(module), unquote(Macro.escape(options))})
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    plugins_with_config =
      env.module
      |> Module.get_attribute(:plugins)
      |> Enum.map(
        fn {plugin, options} ->
          {plugin, Macro.escape(plugin.build_config(options))}
        end
      )

    defs =
      plugins_with_config
      |> Enum.map(
        fn {plugin, config} ->
          quote do
            def fetch_config(unquote(plugin)) do
              unquote(config)
            end
          end
        end
      )
    quote do
      if false do
        # an "idea" to replace module + config arguments?
        @spec __config__() :: %{
          #required(:router) => module,
          required(:mailer) => module,
          #required(:web_module) => module,
          required(:repo) => module,
          required(:schema) => module,
          #required(:opt_app) => atom,
          required(:self) => module,
          required(:layout) => any,
          required(:plugins) => [module],
        }
        def __config__ do
          %{
            layout: false,
            self: __MODULE__,
            #otp_app: unquote(otp_app),
            #web_module: unquote(web_module),
            repo: unquote(fetch_env!(__CALLER__.module)[:repo]),
            mailer: unquote(fetch_env!(__CALLER__.module)[:mailer]),
            schema: unquote(fetch_env!(__CALLER__.module)[:schema]),
            #router: unquote(Module.concat([web_module, :Router, :Helpers])),
            plugins: unquote(Enum.map(plugins_with_config, &(elem(&1, 0)))),
          }
        end
      end

      @spec fetch_config(plugin :: module) :: any
      unquote(defs)

      def fetch_config(_), do: nil

      @spec plugins() :: [module]
      def plugins do
        unquote(Enum.map(plugins_with_config, &(elem(&1, 0))))
      end

      @spec plugins_with_config() :: Keyword.t
      def plugins_with_config do
        unquote(plugins_with_config)
      end
    end
  end

  @doc ~S"""
  Get the list of shared (templates/views) or independant (Haytni stack) files to install
  """
  @spec shared_files_to_install(base_path :: String.t, web_path :: String.t, scope :: String.t, timestamp :: String.t) :: [{:eex | :text, String.t, String.t}]
  def shared_files_to_install(base_path, web_path, scope, timestamp) do
    [
      {:eex, "haytni.ex", Path.join([base_path, "haytni.ex"])},
      {:eex, "views/shared_view.ex", Path.join([web_path, "views", "haytni", scope, "shared_view.ex"])},
      {:eex, "templates/shared/keys.html.eex", Path.join([web_path, "templates", "haytni", scope, "shared", "keys.html.eex"])},
      {:eex, "templates/shared/links.html.eex", Path.join([web_path, "templates", "haytni", scope, "shared", "links.html.eex"])},
      {:eex, "templates/shared/message.html.eex", Path.join([web_path, "templates", "haytni", scope, "shared", "message.html.eex"])},
      # migration
      {:eex, "migrations/0-tokens_creation.exs", Path.join([web_path, "..", "..", "priv", "repo", "migrations", "#{timestamp}_haytni_#{scope}_tokens_creation.exs"])},
      # test
      {:eex, "tests/haytni_quick_views_and_templates_test.exs", Path.join([base_path, "..", "..", "test", "haytni", "haytni_quick_views_and_templates_test.exs"])},
    ]
  end

  @doc ~S"""
  Returns `true` if *plugin* is enabled in the *module* Haytni stack.
  """
  @spec plugin_enabled?(module :: module, plugin :: module) :: boolean
  def plugin_enabled?(module, plugin) do
    plugin in module.plugins()
  end

  # Returns the first non-falsy (`nil` in particular) resulting of calling *fun/2* for each element of *list* or *default* if all elements of (keyword) *list* returned a falsy value.
  @spec map_while(list :: Keyword.t, default :: any, fun :: (atom, any -> any)) :: any
  defp map_while(list, default, fun) do
    try do
      for {k, v} <- list do
        v = fun.(k, v)
        if v do
          throw v
        end
      end
    catch
      val ->
        val
    else
      _ ->
        default
    end
  end

  defp find_user([{plugin, config} | tl], conn, module) do
    result = {conn, user} = plugin.find_user(conn, module, config)
    if user do
      result
    else
      find_user(tl, conn, module)
    end
  end

  defp find_user([], conn, _module) do
    {conn, nil}
  end

  @spec invalid_user?(module :: module, user :: Haytni.user) :: {:error, String.t} | false
  defp invalid_user?(module, user = %_{}) do
    module.plugins_with_config()
    |> map_while(false, &(&1.invalid?(user, module, &2)))
  end

  @doc ~S"""
  Used by plug to extract the current user (if any) from the HTTP
  request (meaning from headers, cookies, etc)
  """
  @spec find_user(module :: module, conn :: Plug.Conn.t) :: {Plug.Conn.t, Haytni.user | nil}
  def find_user(module, conn = %Plug.Conn{}) do
    scoped_session_key = :"#{module.scope()}_id"
    {conn, user, from_session?} = case Plug.Conn.get_session(conn, scoped_session_key) do
      nil ->
        module.plugins_with_config()
        |> find_user(conn, module)
        #|> Enum.reduce_while(
          #{conn, nil},
          #fn plugin, {conn, _user} ->
            #acc = {conn, user} = plugin.find_user(conn, module, config)
            #if conn.halted? or not is_nil(user) ->
              #{:halt, acc}
            #else
              #{:cont, acc}
            #end
          #end
        #)
        |> Tuple.append(false)
      id ->
        {conn, get_user(module, id), true}
    end
    if user do
      case invalid_user?(module, user) do
        {:error, _error} ->
          {Plug.Conn.delete_session(conn, scoped_session_key), nil}
        false ->
          if from_session? do
            {conn, user}
          else
            {:ok, %{conn: conn, user: user}} = on_successful_authentication(module, conn, user)
            conn =
              conn
              |> Plug.Conn.put_session(scoped_session_key, user.id)
              |> Plug.Conn.configure_session(renew: true)

            {conn, user}
          end
      end
    else
      {conn, nil}
    end
  end

  @doc ~S"""
  Register user from controller's *params*.

  Returned value is one of:
    * `{:ok, map}` where *map* is the result of the internals `Ecto.Multi.*` calls
    * `{:error, failed_operation, result_of_failed_operation, changes_so_far}` with:
      + *failed_operation*: the name of the operation which failed
      + *result_of_failed_operation*: its result/returned value
      + *changes_so_far*: same as *map* of the `{:ok, map}` case

  The inserted user will be part of *map* (or eventualy *changes_so_far*) under the key `:user`.

  See `c:Ecto.Repo.insert/2` for *options*.
  """
  @spec create_user(module :: module, attrs :: map, options :: Keyword.t) :: Haytni.multi_result
  def create_user(module, attrs = %{}, options \\ []) do
    schema = module.schema()
    changeset = schema
    |> struct()
    |> schema.create_registration_changeset(attrs)

    multi = Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, changeset, options)

    module.plugins_with_config()
    |> Enum.reduce(
      multi,
      fn {plugin, config}, multi_as_acc ->
        plugin.on_registration(multi_as_acc, module, config)
      end
    )
    |> module.repo().transaction()
  end

  @doc ~S"""
  Runs any custom password validations from the plugins (via their `validate_password/2` callback) of the *module* Haytni
  stack. An `%Ecto.Changeset{}` is returned with the potential validation errors added by the plugins.

  Do **NOT** call it from your function `validate_update_registration/2`, it will be called internally only if needed.
  """
  @spec validate_password(module :: module, changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  def validate_password(module, changeset) do
    module.plugins_with_config()
    |> Enum.reduce(
      changeset,
      fn {plugin, config}, changeset = %Ecto.Changeset{} ->
        plugin.validate_password(changeset, module, config)
      end
    )
  end

  @spec assign_in_multi(multi :: Ecto.Multi.t, name :: Ecto.Multi.name, data :: any) :: Ecto.Multi.t
  defp assign_in_multi(multi = %Ecto.Multi{}, name, data) do
    Ecto.Multi.run(multi, name, fn _repo, _changes -> {:ok, data} end)
  end

  @spec handle_email_change(module :: module, multi :: Ecto.Multi.t, changeset :: Ecto.Changeset.t) :: {Ecto.Multi.t, Ecto.Changeset.t}
  defp handle_email_change(module, multi = %Ecto.Multi{}, changeset = %Ecto.Changeset{changes: %{email: new_email}}) do
    multi =
      multi
      |> assign_in_multi(:new_email, new_email)
      |> assign_in_multi(:old_email, changeset.data.email)
    module.plugins_with_config()
    |> Enum.reduce(
      {multi, changeset},
      fn {plugin, config}, {multi = %Ecto.Multi{}, changeset = %Ecto.Changeset{}} ->
        plugin.on_email_change(multi, changeset, module, config)
      end
    )
  end

  defp handle_email_change(_module, multi = %Ecto.Multi{}, changeset = %Ecto.Changeset{}), do: {multi, changeset}

  @spec handle_password_change(module :: module, changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  defp handle_password_change(module, changeset = %Ecto.Changeset{changes: %{password: _}}) do
    validate_password(module, changeset)
  end

  defp handle_password_change(_module, changeset = %Ecto.Changeset{}), do: changeset

  @doc ~S"""
  Update user's registration, its own registration.

  Works exactly as `create_user`. The only difference is the additionnal parameter: the user to update as first one.

  NOTE: the callbacks of `Ecto.Multi.run` added to the multi by the `on_email_change/4` callback will receive from the
  `Map` they get as their (single) argument the following predefined elements:

    * the updated user as the `:user` key
    * the previous email as `:old_email`
    * `:new_email`: the new email
  """
  @spec update_registration(module :: module, user :: Haytni.user, attrs :: map, options :: Keyword.t) :: Haytni.multi_result
  def update_registration(module, user = %_{}, attrs = %{}, options \\ []) do
    changeset = user
    |> module.schema().update_registration_changeset(attrs)
    changeset = handle_password_change(module, changeset) # TODO: better to be done in RegisterablePlugin.validate_(update|create)_registration?
    {multi = %Ecto.Multi{}, changeset} = handle_email_change(module, Ecto.Multi.new(), changeset) # TODO: better to be done in RegisterablePlugin.validate_(update|create)_registration?
    # create a multi to update user and merge into it the multi from plugins then execute it
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset, options)
    |> Ecto.Multi.append(multi)
    |> module.repo().transaction()
  end

  @doc ~S"""
  Injects the necessary routes for enabled plugins into your Router

  Note that this function is invoked at compile time: you'll need to recompile your application
  to reflect any change in your router.
  """
  def routes(module, options \\ []) do
    as = case module.scope() do
      nil ->
        :haytni
      scope ->
        :"haytni_#{scope}"
    end
    module.plugins()
    |> Enum.map(&(&1.routes(as, options)))
  end

  @doc ~S"""
  Injects `Ecto.Schema.field`s necessary to enabled plugins into your User schema

  Note that this function is invoked at compile time: you'll need to recompile your application
  to reflect any change related to fields injected in your user schema.
  """
  def fields(module) do
    module.plugins()
    |> Enum.into([Haytni.Token.fields(module)], &(&1.fields(module)))
  end

  @doc ~S"""
  Notifies plugins that current user is going to be logged out
  """
  @spec logout(conn :: Plug.Conn.t, module :: module, options :: Keyword.t) :: Plug.Conn.t
  def logout(conn = %Plug.Conn{}, module, options \\ []) do
    conn =
      module.plugins_with_config()
      |> Enum.reverse()
      |> Enum.reduce(conn, fn {plugin, config}, conn -> plugin.on_logout(conn, module, config) end)

    case Keyword.get(options, :scope) do
      :all ->
        Plug.Conn.clear_session(conn)
        #Plug.Conn.configure_session(conn, drop: true)
      _ ->
        conn
        |> Plug.Conn.configure_session(renew: true)
        |> Plug.Conn.delete_session(:"#{module.scope()}_id")
    end
  end

  @spec on_successful_authentication(module :: module, conn :: Plug.Conn.t, user :: Haytni.user) :: Haytni.multi_result
  defp on_successful_authentication(module, conn, user) do
    {conn, multi, changes} =
      module.plugins_with_config()
      |> Enum.reduce(
        {conn, Ecto.Multi.new(), Keyword.new()},
        fn {plugin, config}, {conn, multi, changes} ->
          plugin.on_successful_authentication(conn, user, multi, changes, module, config)
        end
      )

    Ecto.Multi.new()
    |> assign_in_multi(:conn, conn)
    |> Ecto.Multi.update(:user, Ecto.Changeset.change(user, changes))
    |> Ecto.Multi.append(multi)
    |> module.repo().transaction()
  end

  @doc ~S"""
  To be called on (manual) login
  """
  @spec login(conn :: Plug.Conn.t, module :: module, user :: Haytni.user) :: {:ok, Plug.Conn.t} | {:error, String.t}
  def login(conn = %Plug.Conn{}, module, user = %_{}) do
    case invalid_user?(module, user) do
      error = {:error, _message} ->
        error
      false ->
        {:ok, %{conn: conn, user: user}} = on_successful_authentication(module, conn, user)
        conn =
          conn
          |> Plug.Conn.put_session(:"#{module.scope()}_id", user.id)
          |> Plug.Conn.configure_session(renew: true)
          |> Plug.Conn.assign(:"current_#{module.scope()}", user)
        {:ok, conn}
    end
  end

  @doc ~S"""
  Notifies plugins that the authentication failed for *user*.

  If *user* is `nil`, nothing is done.
  """
  @spec authentication_failed(module :: module, user :: Haytni.nilable(Haytni.user)) :: Haytni.multi_result
  def authentication_failed(_module, user = nil) do
    # NOP, for convenience
    {:ok, %{user: user}}
  end

  def authentication_failed(module, user = %_{}) do
    {multi, changes} =
      module.plugins_with_config()
      |> Enum.reduce(
        {Ecto.Multi.new(), Keyword.new()},
        fn {plugin, config}, {multi, keywords} ->
          plugin.on_failed_authentication(user, multi, keywords, module, config)
        end
      )

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, Ecto.Changeset.change(user, changes))
    |> Ecto.Multi.append(multi)
    |> module.repo().transaction()
  end

  @doc ~S"""
  This function is a callback to be called from your `User.create_registration_changeset/2` so validations
  and others internal tasks can be done by plugins at user's registration.
  """
  @spec validate_create_registration(module :: module, changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  def validate_create_registration(module, changeset = %Ecto.Changeset{}) do
    module.plugins_with_config()
    |> Enum.reduce(changeset, fn {plugin, config}, changeset -> plugin.validate_create_registration(changeset, module, config) end)
  end

  @doc ~S"""
  Same than `validate_update_registration/2` but at registration's edition.
  """
  @spec validate_update_registration(module :: module, changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  def validate_update_registration(module, changeset = %Ecto.Changeset{}) do
    module.plugins_with_config()
    |> Enum.reduce(changeset, fn {plugin, config}, changeset -> plugin.validate_update_registration(changeset, module, config) end)
  end

  def user_and_changes_to_changeset(user, changes) do
    Ecto.Changeset.change(user, changes)
  end

  @doc ~S"""
  Update the given user from a list of changes as `Keyword`.

  Returns `{:error, changeset}`  if there was a validation or a known constraint error else `{:ok, struct}`
  where *struct* is the updated user.

  NOTE: for internal use, there isn't any validation. Do **NOT** inject values from controller's *params*!
  """
  @spec update_user_with(module :: module, user :: Haytni.user, changes :: Keyword.t) :: Haytni.repo_nobang_operation(Haytni.user)
  def update_user_with(module, user = %_{}, changes) do
    user
    |> user_and_changes_to_changeset(changes)
    |> module.repo().update()
  end

  @doc ~S"""
  Same as `update_user_with/3` but returns the updated *user* struct or raises if *changes* are invalid.
  """
  @spec update_user_with!(module :: module, user :: Haytni.user, changes :: Keyword.t) :: Haytni.user | no_return
  def update_user_with!(module, user = %_{}, changes) do
    user
    |> user_and_changes_to_changeset(changes)
    |> module.repo().update!()
  end

  @doc ~S"""
  Update user in the same way as `update_user_with/3` but as part of a set of operations (Ecto.Multi).
  """
  @spec update_user_in_multi_with(multi :: Ecto.Multi.t, name :: Ecto.Multi.name, user :: Haytni.user, changes :: Keyword.t) :: Ecto.Multi.t
  def update_user_in_multi_with(multi = %Ecto.Multi{}, name, user = %_{}, changes) do
    Ecto.Multi.update(multi, name, user_and_changes_to_changeset(user, changes))
  end

  @doc ~S"""
  Fetches a user from the *Ecto.Repo* specified in `config :haytni, YourApp.Haytni` as `repo` subkey via the
  attributes specified by *clauses* as a map or a keyword-list.

  Returns `nil` if no user matches.

  Example:

      hulk = Haytni.get_user_by(YourApp.Haytni, first_name: "Robert", last_name: "Banner")
  """
  @spec get_user_by(module :: module, clauses :: Keyword.t | map) :: Haytni.nilable(Haytni.user)
  def get_user_by(module, clauses) do
    module.repo().get_by(module.schema(), clauses)
  end

  @doc ~S"""
  Fetchs a user from its id.

  Returns `nil` if no user matches.

  Example:

      case Haytni.get_user_by(YourApp.Haytni, params["id"]) do
        nil ->
          # not found
        user = %User{} ->
          # do something of user
      end
  """
  @spec get_user(module :: module, id :: any) :: Haytni.nilable(Haytni.user)
  def get_user(module, id) do
    module.repo().get(module.schema(), id)
  end

  @doc ~S"""
  Creates an `%Ecto.Changeset{}` for a new user/account (at registration from a module)
  or from a user (when editing account from a struct)
  """
  @spec change_user(user_or_module :: module | Haytni.user, params :: Haytni.params) :: Ecto.Changeset.t
  def change_user(user_or_module, params \\ %{})

  def change_user(module, params)
    when is_atom(module)
  do
    user =
      module.schema()
      |> struct()
    user.__struct__.create_registration_changeset(user, params)
  end

  def change_user(user = %_{}, params) do
    user.__struct__.update_registration_changeset(user, params)
  end

  @doc ~S"""
  Extracts an Haytni stack (module) from a Plug connection

  Raises if no Haytni's stack was defined (through the router).
  """
  @spec fetch_module_from_conn!(conn :: Plug.Conn.t) :: module
  def fetch_module_from_conn!(conn = %Plug.Conn{}) do
    Map.fetch!(conn.private, :haytni)
  end
end
