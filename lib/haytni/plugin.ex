defmodule Haytni.Plugin do
  @moduledoc ~S"""
  Defines a plugin to be used by Haytni
  """

  @doc ~S"""
  Run at compile time before embedding plugin options once for all. It is a good place to realize some pre-computations.
  """
  @callback build_config(options :: any) :: any

  @doc ~S"""
  This callback let you do any kind of change or additionnal validation on the changeset
  when a user is registering.
  """
  @callback validate_create_registration(changeset :: Ecto.Changeset.t, module :: module, config :: Haytni.config) :: Ecto.Changeset.t

  @doc ~S"""
  Same as `validate_create_registration` but registration's edition as logic between the two
  may be completely different.
  """
  @callback validate_update_registration(changeset :: Ecto.Changeset.t, module :: module, config :: Haytni.config) :: Ecto.Changeset.t

  @doc ~S"""
  Performs validations of user's password. It is a convenient way to enforce your password policy.

  Apply any custom validation(s) to the input `%Ecto.Changeset{}` before returning it.
  """
  @callback validate_password(changeset :: Ecto.Changeset.t, module :: module, config :: Haytni.config) :: Ecto.Changeset.t

  @doc ~S"""
  Returns the `Ecto.Schema.field/1`s as a quoted fragment to be injected in your user schema
  """
  @callback fields(module :: module) :: Macro.t

  @doc ~S"""
  Returns the routes as a quoted fragment to be injected in application's Router
  """
  @callback routes(config :: Haytni.config, prefix_name :: atom, options :: Keyword.t) :: Macro.t

  @doc ~S"""
  Returns a list of files to be (un)installed by the mix tasks haytni.(un)install

  Each file is a 3-elements tuple of the form:

    {*format*, path relative to priv/ of the file to install, path where to install the file}

  Format is one of the following *atom*:

    * `:eex`: the file is an Eex template from which the content is evaluated before being copied
      where the following bindings are set:
      + scope (*atom*, default: `:user`): unsued for now
      + table (*String.t*, default: `"users"`): the name of the users table
      + otp_app (*atom*): inferred, the name of the current OTP application
      + base_module (*module*): inferred, the name of the base non-web module of your Phoenix
        application (the *YourApp* in this documentation)
      + web_module (*module*): inferred, the name of the base web module of your Phoenix application
        (*YourAppWeb* all over this documentation)
      + plugins (*[module]*): the list of the enabled modules
    * `:text`: to copy the file as is
  """
  @callback files_to_install(base_path :: String.t, web_path :: String.t, scope :: String.t, timestamp :: String.t) :: [{:eex | :text, String.t, String.t}]

  @doc ~S"""
  Extract the user from the HTTP request (http authentication, cookies, ...).

  Returns a tuple of the form `{conn, user}` with user being `nil` if no user could be found at
  this early stage.
  """
  @callback find_user(conn :: Plug.Conn.t, module :: module, config :: Haytni.config) :: {Plug.Conn.t, Haytni.user | nil}

  @doc ~S"""
  Check if the user is in a valid state. This callback is intended to let know others plugins
  if we should reject the login (and why).

  Returns `false` if the user is allowed to login else `{:error, reason}` where *reason* is a string,
  an informative to be directly served to the end user.

  For example, you may want to have some kind of ban plugin. This is the way to decline the login:

  ```elixir
  def invalid?(%User{banned: true}, _module, _config), do: {:error, :banned} # or: {:error, dgettext("myapp", "you're banned")}
  def invalid?(%User{banned: _}, _module, _config), do: false
  ```
  """
  @callback invalid?(user :: Haytni.user, module :: module, config :: Haytni.config) :: false | {:error, atom}

  @doc ~S"""
  This callback is invoked when a user logs out. Its purpose is mainly to do some cleanup like removing a cookie.
  """
  @callback on_logout(conn :: Plug.Conn.t, module :: module, config :: Haytni.config, options :: Keyword.t) :: Plug.Conn.t # TODO: or {Plug.Conn.t, Keyword.t} to update the user ?

  @doc ~S"""
  Invoked when an authentication failed (wrong password). It receives the concerned account
  (as it is before calling any on_failed_authentication callback) and a Ecto.Multi where
  to add any additionnal treatment and a Keyword to return after updating it if any change
  have to be done to this user.

  For example, you can use it as follows to count the number of failed attempts to login:

  ```elixir
  def on_failed_authentication(user = %_{}, multi, keyword, _module, _config) do
    {multi, Keyword.put(keyword, :failed_attempts, user.failed_attempts + 1)}
  end
  ```

  Note: we choose to use and pass *keyword* as an accumulator to let the possibility to plugins
  to deal themselves on a conflict (several different plugins which want to alter a same field).
  Even if `Keyword` allows a same key to be defined several times, you'll probably don't want it
  to happen as the last defined value for a given key will (silently) override the others.
  """
  @callback on_failed_authentication(user :: Haytni.user | nil, multi :: Ecto.Multi.t, keywords :: Keyword.t, module :: module, config :: Haytni.config) :: {Ecto.Multi.t, Keyword.t}

  @doc ~S"""
  Invoked when an authentication is successful. Like `on_failed_authentification/3`, it receives
  the current user and a Keyword to return after updating it if you want to bring any change to this
  user to the database.

  To continue our example with a failed attempts counter, on a successful authentication it may be
  a good idea to reset it in this scenario:

  ```elixir
  def on_successful_authentication(conn = %Plug.Conn{}, user = %_{}, multi, keywords, _module, _config) do
    {conn, multi, Keyword.put(keywords, :failed_attempts, 0)}
  end
  ```
  """
  @callback on_successful_authentication(conn :: Plug.Conn.t, user :: Haytni.user, multi :: Ecto.Multi.t, keywords :: Keyword.t, module :: module, config :: Haytni.config) :: {Plug.Conn.t, Ecto.Multi.t, Keyword.t}

  @doc ~S"""
  This callback should be invoked when a user is editing its registration and change its email address.

  It returns a tuple of `{Ecto.Multi, Ecto.Changeset}`, same as its arguments, to permit to the
  callback to add any operation to *multi* or change to *changeset*.

  This callback is called **before** updating the user but the actions added to *multi* will be
  run **after** its update.
  """
  @callback on_email_change(multi :: Ecto.Multi.t, changeset :: Ecto.Changeset.t, module :: module, config :: Haytni.config) :: {Ecto.Multi.t, Ecto.Changeset.t}

  @doc ~S"""
  Invoked to accomplish a task right after user's registration (insert). This callback allows you
  to do some linked changes to the database, send an email or whatever by appending it to *multi*.

  Remember to comply to `Ecto.Multi` functions. In particular `Ecto.Multi.run`: the function
  called by it have to return `{:ok, your value}` or `{:error, your value}`. Also note that
  the inserted user will be passed to the function called by `Ecto.Multi.run` as the `:user`
  key to the map received by the last one as argument.

  The following example illustrate how to send a welcome mail:

  ```elixir
  def on_registration(multi = %Ecto.Multi{}, _module, _config) do
    multi
    |> Ecto.Multi.run(
      :send_welcome_email,
      fn _repo, %{user: user} ->
        send_welcome_email_to(user)
        {:ok, true}
      end
    )
  end
  ```
  """
  @callback on_registration(multi :: Ecto.Multi.t, module :: module, config :: Haytni.config) :: Ecto.Multi.t

  @doc ~S"""
  This callback is meant for a user to delete its own account.

  It could, for example, be used to soft-delete it:

  ```elixir
  def on_delete_user(multi = %Ecto.Multi{}, user = %_{}, _module, _config) do
    Ecto.Multi.update(multi, :user, user, Ecto.Changeset.change(user, deleted: true))
  end
  ```

  Or remove associated files, like its avatar:

  ```elixir
  def on_delete_user(multi = %Ecto.Multi{}, user = %_{}, _module, _config) do
    multi
    # delete the user from the database
    |> Ecto.Multi.delete(:user_deletion, user)
    # then its avatar
    |> Ecto.Multi.run(:avatar_deletion, fn _repo, _changes ->
      case File.rm(user.avatar) do
        :ok -> {:ok, nil}
        error -> error
      end
    end)
  end
  ```
  """
  @callback on_delete_user(multi :: Ecto.Multi.t, user :: Haytni.user, module :: module, config :: Haytni.config) :: Ecto.Multi.t

  @doc ~S"""
  Extend the query used to load a user (by `Haytni.get_user/2` and `Haytni.get_user_by/2`). It is particularly useful to load data tied to users.

  Note: user is aliased by `:user` (named binding)

  Example to load user's roles:

  ```elixir
  @impl Haytni.Callbacks
  def user_query(query) do
    import Ecto.Query

    from(
      [{:user, user}] in query,
      left_join: role in assoc(user, :roles),
      preload: [
        roles: role,
      ]
    )
  end
  ```
  """
  @callback user_query(query :: Ecto.Query.t, module :: module, config :: Haytni.config) :: Ecto.Query.t

  #@callback on_session_start(conn :: Plug.Conn.t, user :: Haytni.user) :: Plug.Conn.t

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      @behaviour unquote(__MODULE__)

      def fields(_module) do
        quote do
        end
      end

      def routes(_config, _prefix_name, _options) do
        quote do
        end
      end

      # NOTE: return a truthy value by default if options/config is not used at all
      # by the plugin to avoid to execute the second part of the || operator
      def build_config(_options), do: true
      def invalid?(_user = %_{}, _module, _config), do: false
      def find_user(conn = %Plug.Conn{}, _module, _config), do: {conn, nil} # TODO {:session | :found | :not_found, Plug.Conn.t, Haytni.nilable(Haytni.user)} ?
      def on_failed_authentication(_user = %_{}, multi = %Ecto.Multi{}, keywords, _module, _config), do: {multi, keywords}
      def files_to_install(_base_path, _web_path, _scope, _timestamp), do: []
      def on_logout(conn = %Plug.Conn{}, _module, _config, _options), do: conn
      def on_registration(multi = %Ecto.Multi{}, _module, _config), do: multi
      def validate_password(changeset = %Ecto.Changeset{}, _module, _config), do: changeset
      def validate_create_registration(changeset = %Ecto.Changeset{}, _module, _config), do: changeset
      def validate_update_registration(changeset = %Ecto.Changeset{}, _module, _config), do: changeset
      def on_email_change(multi = %Ecto.Multi{}, changeset = %Ecto.Changeset{}, _module, _config), do: {multi, changeset}
      def on_successful_authentication(conn = %Plug.Conn{}, _user = %_{}, multi = %Ecto.Multi{}, keywords, _module, _config), do: {conn, multi, keywords}
      def on_delete_user(multi = %Ecto.Multi{}, _user = %_{}, _module, _config), do: multi
      def user_query(query, _module, _config), do: query

      defoverridable [
        build_config: 1,
        fields: 1,
        routes: 3,
        invalid?: 3,
        find_user: 3,
        on_logout: 4,
        on_delete_user: 4,
        on_registration: 3,
        on_email_change: 4,
        files_to_install: 4,
        on_failed_authentication: 5,
        on_successful_authentication: 6,
        validate_password: 3,
        validate_create_registration: 3,
        validate_update_registration: 3,
        user_query: 3,
      ]
    end
  end
end
