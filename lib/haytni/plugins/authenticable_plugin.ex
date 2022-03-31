defmodule Haytni.AuthenticablePlugin do
  @default_login_path "/session"
  @default_logout_method :delete
  @login_path_key :login_path
  @logout_path_key :logout_path
  @logout_method_key :logout_method

  @default_authentication_keys ~W[email]a

  @moduledoc """
  This is a base plugin as it handles basic informations of a user (which are email and hashed password) and their authentication.

  Fields:

    * email (string)
    * encrypted_password (string)

  Configuration:

    * `authentication_keys` (default: `#{inspect(@default_authentication_keys)}`): the key(s), in addition to the password, requested to login. You can redefine it to `~W[name]a`, for example, to ask the username instead of its email address.
    * `hashing_method` (no default): a module implementing the behaviour `ExPassword.Algorithm` to hash and verify passwords
    * `hashing_options` (a map, no default since they are hash-specific): ExPassword settings for hashing passwords

  To support:

    * bcrypt:
      + add `{:expassword_bcrypt, "~> 0.2"}` in `deps/0` to your `mix.exs`
      + set `:hashing_method` to `ExPassword.Bcrypt` on the line `stack #{inspect(__MODULE__)}` and also `hashing_options: %{cost: 10}`
    * argon2:
      + add `{:expassword_argon2, "~> 0.2"}` in `deps/0` to your `mix.exs`
      + set `:hashing_method` to `ExPassword.Argon2` on the line `stack #{inspect(__MODULE__)}` and also `hashing_options: %{type: :argon2id, threads: 2, time_cost: 4, memory_cost: 131072}`

  ```elixir
  stack #{inspect(__MODULE__)},
    authentication_keys: #{inspect(@default_authentication_keys)},
    hashing_method: ExPassword.Bcrypt,
    hashing_options: %{
      cost: 10,
    }
  ```

  Routes:

    * `haytni_<scope>_session_path` (actions: new/create, delete): the generated routes can be customized through the following parameters when you call YourAppWeb.Haytni.routes/1:
      + #{@login_path_key} (default: `#{inspect(@default_login_path)}`): custom path assigned to the sign-in route
      + #{@logout_path_key} (default: same value as *login_path*): the path for th sign out route
      + #{@logout_method_key} (default: `#{inspect(@default_logout_method)}`): the HTTP method to use for the user to log out, in case where the default DELETE method were not well supported by your clients

      ```elixir
      # lib/your_app_web/router.ex
      defmodule YourAppWeb.Router do
        # ...
        scope ... do
          YourAppWeb.Haytni.routes(
            #{@login_path_key}: "/login",
            #{@logout_path_key}: "/logout",
            #{@logout_method_key}: :get
          )
        end
        # ...
      end
      ```
  """

  import Haytni.Gettext

  defmodule Config do
    defstruct hashing_method: nil, hashing_options: nil, authentication_keys: ~W[email]a

    @type t :: %__MODULE__{
      hashing_method: module,
      hashing_options: %{optional(atom) => any},
      authentication_keys: [atom, ...],
    }
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %Haytni.AuthenticablePlugin.Config{}
    |> Haytni.Helpers.merge_config(options)
  end

  @impl Haytni.Plugin
  def files_to_install(_base_path, web_path, scope, timestamp) do
    [
      {:eex, "views/session_view.ex", Path.join([web_path, "views", "haytni", scope, "session_view.ex"])},
      {:eex, "templates/session/new.html.heex", Path.join([web_path, "templates", "haytni", scope, "session", "new.html.heex"])},
      # migration
      {:eex, "migrations/0-authenticable_changes.exs", Path.join([web_path, "..", "..", "priv", "repo", "migrations", "#{timestamp}_haytni_authenticable_#{scope}_changes.exs"])},
    ]
  end

  @impl Haytni.Plugin
  def fields(_module) do
    quote do
      field :email, :string # UNIQUE
      field :encrypted_password, :string, redact: true # TODO: load_in_query: false
      field :password, :string, virtual: true, redact: true

      timestamps(updated_at: false, type: :utc_datetime)
    end
  end

  @impl Haytni.Plugin
  def routes(_config, prefix_name, options) do
    prefix_name = :"#{prefix_name}_session"
    login_path_set? = Keyword.has_key?(options, @login_path_key)
    login_path = Keyword.get(options, @login_path_key, @default_login_path)
    logout_path = Keyword.get(options, @logout_path_key, login_path)
    logout_method = Keyword.get(options, @logout_method_key, @default_logout_method)
    quote bind_quoted: [prefix_name: prefix_name, login_path_set?: login_path_set?, login_path: login_path, logout_path: logout_path, logout_method: logout_method] do
      if login_path_set? do
        get login_path, HaytniWeb.Authenticable.SessionController, :new, as: prefix_name
        post login_path, HaytniWeb.Authenticable.SessionController, :create, as: prefix_name
      else
        # to keep old behaviour - GET "/session/new" for new and POST "/session" for create
        resources login_path, HaytniWeb.Authenticable.SessionController, singleton: true, only: ~W[new create]a, as: prefix_name
      end
      match logout_method, logout_path, HaytniWeb.Authenticable.SessionController, :delete, as: prefix_name
    end
  end

  @impl Haytni.Plugin
  def validate_create_registration(changeset = %Ecto.Changeset{valid?: true, changes: %{password: password}}, _module, config) do
    hash_password(changeset, password, config)
  end

  def validate_create_registration(changeset = %Ecto.Changeset{}, _module, _config) do
    changeset
  end

  @doc ~S"""
  Converts the parameters received for authentication by the controller in a `%Ecto.Changeset{}` to handle and validate
  user inputs according to plugin's configuration (`authentication_keys`).
  """
  @spec session_changeset(config :: Config.t, request_params :: Haytni.params) :: Ecto.Changeset.t
  def session_changeset(config, session_params \\ %{}) do
    Haytni.Helpers.to_changeset(session_params, nil, [:password | config.authentication_keys])
  end

  @doc ~S"""
  The translated string to display when credentials (password and/or email by default) are wrong.
  """
  @spec invalid_credentials_message() :: String.t
  def invalid_credentials_message do
    dgettext("haytni", "Invalid combination of credentials")
  end

  @doc ~S"""
  Authentificates a user.

  Returns:

    * `{:ok, user}` if crendentials are correct and *user* is valid
    * `{:error, changeset}` if credentials are incorrect or *user* is invalid (rejected by a
      `Haytni.Plugin.invalid?` callback by a plugin in the stack)
  """
  @spec authenticate(conn :: Plug.Conn.t, module :: module, config :: Config.t, session_params :: Haytni.params) :: Haytni.repo_nobang_operation(Plug.Conn.t)
  def authenticate(conn = %Plug.Conn{}, module, config, session_params = %{}) do
    changeset = session_changeset(config, session_params)

    changeset
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, sanitized_params} ->
        user = Haytni.get_user_by(module, Map.delete(sanitized_params, :password))

        user
        |> ExPassword.verify_and_rehash_if_needed(sanitized_params.password, :encrypted_password, config.hashing_method, config.hashing_options)
        |> case do
          {:ok, changes} ->
            case Haytni.login(conn, module, user, changes) do
              result = {:ok, _conn} ->
                result
              {:error, message} ->
                Haytni.Helpers.apply_base_error(changeset, message)
            end
          {:error, _reason} ->
            Haytni.authentication_failed(module, user)
            Haytni.Helpers.apply_base_error(changeset, invalid_credentials_message())
        end
      error = {:error, %Ecto.Changeset{}} ->
        error
    end
  end

  @doc ~S"""
  Returns `true` if *password* matches *user*'s current hash (*encrypted_password* field)
  """
  @spec valid_password?(user :: Haytni.nilable(Haytni.user), password :: String.t, config :: Config.t) :: boolean
  def valid_password?(user, password, config)

  def valid_password?(nil, password, config = %Config{})
    when is_binary(password)
  do
    hash_password(password, config) # for timing attacks
    false
  end

  def valid_password?(user = %_{}, password, _config)
    when is_binary(password)
  do
    ExPassword.verify?(password, user.encrypted_password)
  end

  @doc ~S"""
  Hashes a password.

  Returns the hash of the password after having hashed it
  """
  @spec hash_password(password :: String.t, config :: Config.t) :: String.t
  def hash_password(password, config) do
    ExPassword.hash(config.hashing_method, password, config.hashing_options)
  end

if false do
  @doc ~S"""
  Hashes a password directly in a `Ecto.Changeset` (as change). Meaning the password is hashed as
  the *encrypted_password* field of the changeset then the *password* field is cleared to `nil`.

  The modified changeset is returned.
  """
end
  @spec hash_password(changeset :: Ecto.Changeset.t, password :: String.t, config :: Config.t) :: Ecto.Changeset.t
  defp hash_password(changeset = %Ecto.Changeset{}, password, config) do
    Ecto.Changeset.change(changeset, encrypted_password: hash_password(password, config), password: nil)
  end
end
