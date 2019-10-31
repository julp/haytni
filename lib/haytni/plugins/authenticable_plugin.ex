defmodule Haytni.AuthenticablePlugin do
  @moduledoc ~S"""
  This is a base plugin as it handles basic informations of a user (which are email and hashed password) and their authentification.

  Fields:

    * email (string)
    * encrypted_password (string)

  Configuration:

    * `authentication_keys` (default: `~W[email]a`): the key(s), in addition to the password, requested to login. You can redefine it to `~W[name]a`, for example, to ask the username instead of its email address.
    * password hashing algorithm (default: bcrypt):
      + `password_hash_fun` (default: `&Bcrypt.hash_pwd_salt/1`): the function to hash a password
      + `password_check_fun` (default: `&Bcrypt.check_pass/3`): the function to check if a password matches its hash


  Routes:

    * `session_path` (actions: new/create)
  """

  import Plug.Conn
  import Ecto.Changeset
  import Haytni.Gettext

  use Haytni.Plugin
  use Haytni.Config, [
    authentication_keys: ~W[email]a,
    # NOTE/TODO: have a library like password_* functions from PHP
    # to allow you to change at any time of algorithm between bcrypt,
    # argon2 and pbkdf2
    password_check_fun: &Bcrypt.check_pass/3,
    password_hash_fun: &Bcrypt.hash_pwd_salt/1,
  ]

  @impl Haytni.Plugin
  def files_to_install do
    import Mix.Tasks.Haytni.Install, only: [web_path: 0, timestamp: 0]
    [
      {:eex, "views/session_view.ex", Path.join([web_path(), "views", "haytni", "session_view.ex"])},
      {:eex, "templates/session/new.html.eex", Path.join([web_path(), "templates", "haytni", "session", "new.html.eex"])},
      # migration
      {:eex, "migrations/authenticable_changes.ex", Path.join([web_path(), "..", "..", "priv", "repo", "migrations", "#{timestamp()}_haytni_authenticable_changes.ex"])}, # TODO: less "hacky"
      # TODO: put shared stuffs elsewhere
      {:eex, "views/shared_view.ex", Path.join([web_path(), "views", "haytni", "shared_view.ex"])},
      {:eex, "templates/shared/keys.html.eex", Path.join([web_path(), "templates", "haytni", "shared", "keys.html.eex"])},
      {:eex, "templates/shared/links.html.eex", Path.join([web_path(), "templates", "haytni", "shared", "links.html.eex"])},
      {:eex, "templates/shared/message.html.eex", Path.join([web_path(), "templates", "haytni", "shared", "message.html.eex"])}
    ]
  end

  @impl Haytni.Plugin
  def fields do
    quote do
      field :email, :string # UNIQUE
      field :encrypted_password, :string
      field :password, :string, virtual: true
    end
  end

  @impl Haytni.Plugin
  def routes(_scope, _options) do
    quote do
      resources "/session", HaytniWeb.Authenticable.SessionController, singleton: true, only: ~W[new create delete]a
    end
  end

  @impl Haytni.Plugin
  def find_user(conn = %Plug.Conn{}) do
    user_id = get_session(conn, :user_id)
    user = user_id && Haytni.Users.get_user(user_id)
    {conn, user}
  end

  @impl Haytni.Plugin
  def validate_create_registration(changeset = %Ecto.Changeset{valid?: true, changes: %{password: password}}) do
    hash_password(changeset, password)
  end

  def validate_create_registration(changeset = %Ecto.Changeset{}) do
    changeset
  end

  @impl Haytni.Plugin
  def validate_update_registration(changeset = %Ecto.Changeset{valid?: true, changes: %{current_password: current_password}}) do
    new_password = get_change(changeset, :password)
    if get_change(changeset, :email) || new_password do
      case check_password(changeset.data, current_password) do
        {:ok, _user} ->
          if new_password do
            hash_password(changeset, new_password)
          else
            changeset
          end
        {:error, _message} ->
          changeset
          |> add_error(:current_password, dgettext("haytni", "password mismatch"))
      end
    else
      changeset
    end
  end

  def validate_update_registration(changeset = %Ecto.Changeset{}) do
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
  Authentificates a user.

  Returns:

    * `{:ok, user}` if crendentials are correct and *user* is valid
    * `{:error, reason}` if credentials are incorrect or *user* is invalid (rejected by a
      `Haytni.Plugin.invalid?` callback by a plugin in the stack)
  """
  @spec authentificate(conn :: Plug.Conn.t, session :: Haytni.Session.t) :: {:ok, Plug.Conn.t} | {:error, String.t}
  def authentificate(conn = %Plug.Conn{}, session) do # session = %Haytni.Session{}
    clauses = authentication_keys()
    |> Enum.into(Keyword.new(), fn key -> {key, Map.fetch!(session, key)} end)

    user = Haytni.Users.get_user_by(clauses)
    user
    |> check_password(session.password, hide_user: true)
    |> case do
      {:ok, user} ->
        Haytni.login(conn, user)
      {:error, _message} ->
        Haytni.authentification_failed(user)
        {:error, dgettext("haytni", "Invalid combination of credentials")}
    end
  end

  @spec check_password(user :: struct, password :: String.t, options :: Keyword.t) :: {:ok, struct} | {:error, String.t}
  defp check_password(user, password, options \\ []) do
    password_check_fun().(user, password, options)
  end

  @doc ~S"""
  Hashes a password.

  Returns the hash of the password.
  """
  @spec hash_password(password :: String.t) :: String.t
  def hash_password(password) do
    password_hash_fun().(password)
  end

if false do
  @doc ~S"""
  Hashes a password directly in a `Ecto.Changeset` (as change). Meaning the password is hashed as
  the *encrypted_password* field of the changeset then the *password* field is cleared to `nil`.

  The modified changeset is returned.
  """
end
  @spec hash_password(changeset :: Ecto.Changeset.t, password :: String.t) :: Ecto.Changeset.t
  defp hash_password(changeset = %Ecto.Changeset{}, password) do
    change(changeset, encrypted_password: hash_password(password), password: nil)
  end
end
