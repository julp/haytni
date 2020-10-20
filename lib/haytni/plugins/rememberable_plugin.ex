defmodule Haytni.RememberablePlugin do
  @default_remember_for {2, :week}
  @default_remember_cookie_name "remember_token"
  @default_remember_cookie_options [
    http_only: true,
    extra: "Samesite=Strict",
  ]
  @default_remember_token_length 16

  @moduledoc """
  This plugin makes artificialy last user's authentication by creating a cookie which stores a token for remembering the user.

  This cookie is cleared when user's manually logout.

  Fields:

    * remember_token (string, nullable, unique, default: `NULL`): the token to sign in automatically (`NULL` if the account doesn't use this function)
    * remember_created_at (datetime@utc, nullable, default: `NULL`): when the token was generated (also `NULL` if the account doesn't use this function)

  Configuration:

    * `remember_for` (default: `#{inspect(@default_remember_for)}`): the period of validity of the token/which the user won't be asked for credentials
    * `remember_salt` (default: `""`): the salt to (de)cipher the token stored in the (signed) cookie
    * `remember_token_length` (default: `#{inspect(@default_remember_token_length)}`): the length of the token (before being ciphered)
    * `remember_cookie_name` (default: `#{inspect(@default_remember_cookie_name)}`): the name of the cookie holding the token for automatic sign in
    * `remember_cookie_options` (default: `#{inspect(@default_remember_cookie_options)}`): to set custom options of the cookie (options are: *domain*, *max_age*, *path*, *http_only*, *secure* and *extra*, see documentation of Plug.Conn.put_resp_cookie/4)

          stack Haytni.RememberablePlugin,
            remember_salt: "",
            remember_for: #{inspect(@default_remember_for)},
            remember_token_length: #{inspect(@default_remember_token_length)},
            remember_cookie_name: #{inspect(@default_remember_cookie_name)},
            remember_cookie_options: #{inspect(@default_remember_cookie_options)}

  Routes: none
  """

  import Plug.Conn

  defmodule Config do
    defstruct remember_salt: "",
      remember_for: {2, :week},
      remember_token_length: 16,
      remember_cookie_name: "remember_token",
      remember_cookie_options: [
        #domain:
        #max_age:
        #path:
        http_only: true,
        #secure:
        extra: "Samesite=Strict",
      ]

    @type t :: %__MODULE__{
      remember_salt: String.t,
      remember_for: Haytni.duration,
      remember_token_length: pos_integer,
      remember_cookie_name: String.t,
      remember_cookie_options: Keyword.t,
    }
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    # TODO: generate a random remember_salt at compile time if it is nil/""?
    %Haytni.RememberablePlugin.Config{}
    |> Haytni.Helpers.merge_config(options, ~W[remember_for]a)
  end

  @impl Haytni.Plugin
  def files_to_install(_base_path, web_path, scope, timestamp) do
    [
      # migration
      {:eex, "migrations/0-rememberable_changes.exs", Path.join([web_path, "..", "..", "priv", "repo", "migrations", "#{timestamp}_haytni_rememberable_#{scope}_changes.exs"])},
    ]
  end

  @impl Haytni.Plugin
  def fields(_module) do
    quote do
      field :remember_token, :string, default: nil # NULLABLE, UNIQUE
      field :remember_created_at, :utc_datetime, default: nil # NULLABLE
    end
  end

  @doc ~S"""
  Sign *remember_token*
  """
  @spec sign_token(conn :: Plug.Conn.t, remember_token :: String.t, config :: Config.t) :: String.t
  def sign_token(conn = %Plug.Conn{}, remember_token, config) do
    Phoenix.Token.sign(conn, config.remember_salt, remember_token)
  end

  @doc ~S"""
  Fetches the rememberme token from its signature.

  Returns the token as `{:ok, string}` but `{:error, :invalid}` if signature is corrupted in any way or `{:error, :missing}` if *signed_token* is `nil`
  """
  @spec verify_token(conn :: Plug.Conn.t, signed_token :: String.t | nil, config :: Config.t) :: {:ok, String.t} | {:error, :invalid | :missing}
  def verify_token(conn, signed_token, config) do
    Phoenix.Token.verify(conn, config.remember_salt, signed_token, max_age: config.remember_for)
  end

  @impl Haytni.Plugin
  def find_user(conn = %Plug.Conn{}, module, config) do
    conn = Plug.Conn.fetch_cookies(conn)
    with(
      {:ok, signed_token} <- Map.fetch(conn.cookies, config.remember_cookie_name),
      {:ok, remember_token} <- verify_token(conn, signed_token, config),
      user when not is_nil(user) <- Haytni.get_user_by(module, remember_token: remember_token)
    ) do
      {conn, user}
    else
      _ ->
        {remove_rememberme_cookie(conn, config), nil}
    end
  end

  @impl Haytni.Plugin
  # The checkbox "remember me" is checked (present in params)
  def on_successful_authentication(conn = %Plug.Conn{params: %{"session" => %{"remember" => _}}}, user = %_{}, multi = %Ecto.Multi{}, keyword, _module, config) do
    {remember_token, keyword} = if is_nil(user.remember_token) or rememberable_token_expired?(user, config) do
      remember_token = config.remember_token_length
      |> Haytni.Token.generate()

      keyword = keyword
      |> Keyword.put(:remember_created_at, Haytni.Helpers.now())
      |> Keyword.put(:remember_token, remember_token)

      {remember_token, keyword}
    else
      {user.remember_token, keyword}
    end
    conn = add_rememberme_cookie(conn, remember_token, config)
    {conn, multi, keyword}
  end

  # The checkbox "remember me" is not checked (absent from params)
  def on_successful_authentication(conn = %Plug.Conn{}, _user = %_{}, multi = %Ecto.Multi{}, keyword, _module, _config) do
    {conn, multi, keyword}
  end

  @spec rememberable_token_expired?(user :: Haytni.user, config :: Config.t) :: boolean
  defp rememberable_token_expired?(user, config) do
    DateTime.diff(DateTime.utc_now(), user.remember_created_at) >= config.remember_for
  end

  @doc ~S"""
  Sign *remember_token* then add it to *conn* response's cookies.

  Returns the updated `%Plug.Conn{}` with our rememberme cookie
  """
  @spec add_rememberme_cookie(conn :: Plug.Conn.t, remember_token :: String.t, config :: Config.t) :: Plug.Conn.t
  def add_rememberme_cookie(conn = %Plug.Conn{}, remember_token, config) do
    signed_token = sign_token(conn, remember_token, config)

    conn
    |> put_resp_cookie(config.remember_cookie_name, signed_token, remember_cookie_options_with_max_age(config))
  end

  @spec remove_rememberme_cookie(conn :: Plug.Conn.t, config :: Config.t) :: Plug.Conn.t
  defp remove_rememberme_cookie(conn = %Plug.Conn{}, config) do
    delete_resp_cookie(conn, config.remember_cookie_name, remember_cookie_options_with_max_age(config))
  end

  @spec remember_cookie_options_with_max_age(config :: Config.t) :: Keyword.t
  defp remember_cookie_options_with_max_age(config) do
    config.remember_cookie_options
    |> Keyword.put_new(:max_age, DateTime.to_unix(Haytni.Helpers.now()) + config.remember_for)
  end

  @impl Haytni.Plugin
  def on_logout(conn = %Plug.Conn{}, _module, config) do
    remove_rememberme_cookie(conn, config)
  end
end
