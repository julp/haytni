defmodule Haytni.AuthenticablePlugin do
  @moduledoc ~S"""
  This is a base plugin as it handles basic informations of a user (which are email and hashed password) and their authentication.

  Fields:

    * email (string)
    * encrypted_password (string)

  Configuration:

    * `authentication_keys` (default: `~W[email]a`): the key(s), in addition to the password, requested to login. You can redefine it to `~W[name]a`, for example, to ask the username instead of its email address.
    * password hashing algorithm (default: bcrypt):
      + `password_hash_fun` (default: `&Bcrypt.hash_pwd_salt/1`): the function to hash a password
      + `password_check_fun` (default: `&Bcrypt.check_pass/3`): the function to check if a password matches its hash

    To use:

      * `pbkdf2` add `{:pbkdf2_elixir, "~> 1.0"}` as `deps` to your `mix.exs` then set `password_hash_fun` to `&Pbkdf2.hash_pwd_salt/1` and `password_check_fun` to `&Pbkdf2.check_pass/2` in config/config.exs
      * `argon2` add `{:argon2_elixir, "~> 2.0"}` as `deps` to your `mix.exs` then set `password_hash_fun` to `&Argon2.hash_pwd_salt/1` and `password_check_fun` to ` &Argon2.check_pass/2` in config/config.exs

            stack Haytni.AuthenticablePlugin,
              authentication_keys: ~W[email]a,
              password_check_fun: &Bcrypt.check_pass/3,
              password_hash_fun: &Bcrypt.hash_pwd_salt/1

  Routes:

    * `session_path` (actions: new/create)
  """

  import Haytni.Gettext

  defmodule Config do
    defstruct authentication_keys: ~W[email]a,
      # NOTE/TODO: have a library like password_* functions from PHP
      # to allow you to change at any time of algorithm between bcrypt,
      # argon2 and pbkdf2
      password_check_fun: &Bcrypt.check_pass/3,
      password_hash_fun: &Bcrypt.hash_pwd_salt/1

    @type t :: %__MODULE__{
      authentication_keys: [atom],
      password_check_fun: (struct, Comeonin.PasswordHash.password_hash, Comeonin.PasswordHash.opts -> {:ok, struct} | {:error, String.t}),
      password_hash_fun: (Comeonin.PasswordHash.password -> Comeonin.PasswordHash.password_hash),
    }
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %Haytni.AuthenticablePlugin.Config{}
    |> Haytni.Helpers.merge_config(options)
  end

  @impl Haytni.Plugin
  def files_to_install do
    import Mix.Tasks.Haytni.Install, only: [base_path: 0, web_path: 0, timestamp: 0]
    [
      {:eex, "views/session_view.ex", Path.join([web_path(), "views", "haytni", "session_view.ex"])},
      {:eex, "templates/session/new.html.eex", Path.join([web_path(), "templates", "haytni", "session", "new.html.eex"])},
      # migration
      {:eex, "migrations/0-authenticable_changes.ex", Path.join([web_path(), "..", "..", "priv", "repo", "migrations", "#{timestamp()}_haytni_authenticable_changes.ex"])}, # TODO: less "hacky"
      # TODO: put shared stuffs elsewhere
      {:eex, "haytni.ex", Path.join([base_path(), "haytni.ex"])},
      {:eex, "views/shared_view.ex", Path.join([web_path(), "views", "haytni", "shared_view.ex"])},
      {:eex, "templates/shared/keys.html.eex", Path.join([web_path(), "templates", "haytni", "shared", "keys.html.eex"])},
      {:eex, "templates/shared/links.html.eex", Path.join([web_path(), "templates", "haytni", "shared", "links.html.eex"])},
      {:eex, "templates/shared/message.html.eex", Path.join([web_path(), "templates", "haytni", "shared", "message.html.eex"])},
    ]
  end

  @impl Haytni.Plugin
  def fields(_module) do
    quote do
      field :email, :string # UNIQUE
      field :encrypted_password, :string
      field :password, :string, virtual: true
    end
  end

  @impl Haytni.Plugin
  def routes(_options) do
    quote do
      resources "/session", HaytniWeb.Authenticable.SessionController, singleton: true, only: ~W[new create delete]a
    end
  end

  @impl Haytni.Plugin
  def validate_create_registration(changeset = %Ecto.Changeset{valid?: true, changes: %{password: password}}, config) do
    hash_password(changeset, password, config)
  end

  def validate_create_registration(changeset = %Ecto.Changeset{}, _config) do
    changeset
  end

  @impl Haytni.Plugin
  def validate_update_registration(changeset = %Ecto.Changeset{valid?: true, changes: %{current_password: current_password}}, config) do
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

  def validate_update_registration(changeset = %Ecto.Changeset{}, _config) do
    changeset
  end

  if false do
    @impl Haytni.Plugin
    def shared_links(:new_session), do: []

    def shared_links(_) do
      [
        {dgettext("haytni", "Sign in"), session_path(...Endpoint, :new)}
      ]
    end
  end

  @doc ~S"""
  Converts the parameters received for authentication by the controller in a `%Ecto.Changeset{}` to handle and validate
  user inputs according to plugin's configuration (`authentication_keys`).
  """
  @spec session_changeset(config :: Config.t, request_params :: %{String.t => String.t}) :: Ecto.Changeset.t
  def session_changeset(config, session_params \\ %{}) do
    Haytni.Helpers.to_changeset(session_params, [:password | config.authentication_keys])
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
  @spec authenticate(conn :: Plug.Conn.t, module :: module, config :: Config.t, session_params :: %{optional(String.t) => String.t}) :: {:ok, Plug.Conn.t} | {:error, Ecto.Changeset.t}
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
            case Haytni.login(conn, module, user) do
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
