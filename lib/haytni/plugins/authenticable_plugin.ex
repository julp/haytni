defmodule Haytni.AuthenticablePlugin do
  @default_login_path "/session"
  @default_logout_method :delete
  @login_path_key :login_path
  @logout_path_key :logout_path
  @logout_method_key :logout_method

  @default_session_maxlifetime {2, :hour}
  @default_authentication_keys ~W[email]a
  @default_password_hash_fun &Bcrypt.hash_pwd_salt/1
  @default_password_check_fun &Bcrypt.check_pass/3

  @moduledoc """
  This is a base plugin as it handles basic informations of a user (which are email and hashed password) and their authentication.

  Fields:

    * email (string)
    * encrypted_password (string)

  Configuration:

    * `authentication_keys` (default: `#{inspect(@default_authentication_keys)}`): the key(s), in addition to the password, requested to login. You can redefine it to `~W[name]a`, for example, to ask the username instead of its email address.
    * password hashing algorithm (default: bcrypt):
      + `password_hash_fun` (default: `#{inspect(@default_password_hash_fun)}`): the function to hash a password
      + `password_check_fun` (default: `#{inspect(@default_password_check_fun)}`): the function to check if a password matches its hash
    * session_maxlifetime (default: `#{inspect(@default_session_maxlifetime)}`): nowadays, by default, browsers (Chrom* or Firefox for example) don't delete session cookies when you close them. This setting enforces session to not last longer than they should.

  To use:

    * `pbkdf2` add `{:pbkdf2_elixir, "~> 1.0"}` as `deps` to your `mix.exs` then set `password_hash_fun` to `&Pbkdf2.hash_pwd_salt/1` and `password_check_fun` to `&Pbkdf2.check_pass/2` in config/config.exs
    * `argon2` add `{:argon2_elixir, "~> 2.0"}` as `deps` to your `mix.exs` then set `password_hash_fun` to `&Argon2.hash_pwd_salt/1` and `password_check_fun` to ` &Argon2.check_pass/2` in config/config.exs

  ```elixir
  stack #{inspect(__MODULE__)},
    session_maxlifetime: #{inspect(@default_session_maxlifetime)},
    authentication_keys: #{inspect(@default_authentication_keys)},
    password_check_fun: #{inspect(@default_password_check_fun)},
    password_hash_fun: #{inspect(@default_password_hash_fun)}
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
    defstruct authentication_keys: ~W[email]a,
      session_maxlifetime: {2, :hour},
      # NOTE/TODO: have a library like password_* functions from PHP
      # to allow you to change at any time of algorithm between bcrypt,
      # argon2 and pbkdf2
      password_check_fun: &Bcrypt.check_pass/3,
      password_hash_fun: &Bcrypt.hash_pwd_salt/1

    @type t :: %__MODULE__{
      authentication_keys: [atom, ...],
      session_maxlifetime: Haytni.duration,
      password_check_fun: (struct, Comeonin.PasswordHash.password_hash, Comeonin.PasswordHash.opts -> {:ok, struct} | {:error, String.t}),
      password_hash_fun: (Comeonin.PasswordHash.password -> Comeonin.PasswordHash.password_hash),
    }
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %Haytni.AuthenticablePlugin.Config{}
    |> Haytni.Helpers.merge_config(options, ~W[session_maxlifetime]a)
  end

  @impl Haytni.Plugin
  def files_to_install(_base_path, web_path, scope, timestamp) do
    [
      {:eex, "views/session_view.ex", Path.join([web_path, "views", "haytni", scope, "session_view.ex"])},
      {:eex, "templates/session/new.html.eex", Path.join([web_path, "templates", "haytni", scope, "session", "new.html.eex"])},
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
  def routes(prefix_name, options) do
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

  @impl Haytni.Plugin
  def validate_update_registration(changeset = %Ecto.Changeset{valid?: true, changes: %{current_password: current_password}}, _module, config) do
    new_password = Ecto.Changeset.get_change(changeset, :password)
    if Ecto.Changeset.get_change(changeset, :email) || new_password do
      case check_password(changeset.data, current_password, config) do
        {:ok, _user} ->
          if new_password do
            hash_password(changeset, new_password, config)
          else
            changeset
          end
        {:error, _message} ->
          changeset
          |> Ecto.Changeset.add_error(:current_password, dgettext("haytni", "password mismatch"))
      end
    else
      changeset
    end
  end

  def validate_update_registration(changeset = %Ecto.Changeset{}, _module, _config) do
    changeset
  end

  use Haytni.Tokenable

  @impl Haytni.Tokenable
  def token_context(nil) do
    "authenticable"
  end

  @spec module_to_session_key(module :: module) :: atom
  defp module_to_session_key(module) do
    :"#{module.scope()}_token"
  end

  # TODO: move find_user + on_successful_authentication + on_logout (session handling) to a separate plugin?
  @impl Haytni.Plugin
  def find_user(conn = %Plug.Conn{}, module, config) do
    scoped_session_key = module_to_session_key(module)
    if token = Plug.Conn.get_session(conn, scoped_session_key) do
      with(
        {:ok, authenticable_token} <- Haytni.Token.url_decode(token),
        user when not is_nil(user) <- Haytni.Token.user_from_token_with_mail_match(module, authenticable_token, token_context(nil), config.session_maxlifetime)
      ) do
        {conn, user}
      else
        _ ->
          {Plug.Conn.delete_session(conn, scoped_session_key), nil}
      end
    else
      {conn, nil}
    end
  end

  @impl Haytni.Plugin
  def on_successful_authentication(conn = %Plug.Conn{}, user = %_{}, multi = %Ecto.Multi{}, keyword, module, _config) do
    token = Haytni.Token.build_and_assoc_token(user, user.email, token_context(nil))

    conn =
      conn
      |> Plug.Conn.put_session(module_to_session_key(module), Haytni.Token.url_encode(token))
      |> Plug.Conn.configure_session(renew: true)

    {conn, Ecto.Multi.insert(multi, :authenticable_token, token), keyword}
  end

  @impl Haytni.Plugin
  def on_logout(conn = %Plug.Conn{}, module, _config) do
    options = [] # TODO
    case Keyword.get(options, :scope) do
      :all ->
        Plug.Conn.clear_session(conn)
        #Plug.Conn.configure_session(conn, drop: true)
      _ ->
        conn
        |> Plug.Conn.configure_session(renew: true)
        |> Plug.Conn.delete_session(module_to_session_key(module))
    end
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
        |> check_password(sanitized_params.password, config, hide_user: true)
        |> case do
          {:ok, user} ->
            case Haytni.set_user(conn, module, user) do
              result = {:ok, _conn} ->
                result
              {:error, message} ->
                Haytni.Helpers.apply_base_error(changeset, message)
            end
          {:error, _message} ->
            Haytni.authentication_failed(module, user)
            Haytni.Helpers.apply_base_error(changeset, invalid_credentials_message())
        end
      error = {:error, %Ecto.Changeset{}} ->
        error
    end
  end

  @doc ~S"""
  Returns `true` if *password* matches *user*'s current hash (*encrypted_password* field)

  *options* is a keyword-list passed to Comeonin:
    * `hide_user` (boolean, default: `true`): if not `false`, protects against timing attacks
    * `hash_key` (atom, looks by default for a `password_hash` and `encrypted_password` key): the name of the key containing the hash in *user*
  """
  @spec check_password(user :: Haytni.user | nil, password :: String.t, config :: Config.t, options :: Keyword.t) :: {:ok, Haytni.user} | {:error, String.t}
  def check_password(user, password, config, options \\ []) do
    config.password_check_fun.(user, password, options)
  end

  @doc ~S"""
  Hashes a password.

  Returns the hash of the password after having hashed it with `config.password_hash_fun`
  """
  @spec hash_password(password :: String.t, config :: Config.t) :: String.t
  def hash_password(password, config) do
    config.password_hash_fun.(password)
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
