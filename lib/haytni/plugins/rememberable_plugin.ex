defmodule Haytni.RememberablePlugin do
  @moduledoc ~S"""
  This plugin makes artificialy last user's authentification by creating a cookie which stores a token for remembering the user.

  This cookie is cleared when user's manually logout.

  Fields:

    * remember_token (string, nullable, unique, default: `NULL`): the token to sign in automatically (`NULL` if the account doesn't use this function)
    * remember_created_at (datetime@utc, nullable, default: `NULL`): when the token was generated (also `NULL` if the account doesn't use this function)

  Configuration:

    * `remember_for` (default: `{2, :week}`): the period of validity of the token/which the user won't be asked for credentials
    * `remember_salt` (default: `""`): the salt to (de)cipher the token stored in the (signed) cookie
    * `remember_token_length` (default: 16): the length of the token (before being ciphered)
    * `remember_cookie_name` (default: `"remember_token"`): the name of the cookie holding the token for automatic sign in
    * `remember_cookie_options` (default: `[http_only: true]`): to set custom options of the cookie (options are: *domain*, *max_age*, *path*, *http_only*, *secure* and *extra*, see documentation of Plug.Conn.put_resp_cookie/4)

  Routes: none
  """
  import Plug.Conn

  use Haytni.Plugin
  use Haytni.Config, [
    remember_salt: "",
    remember_for: {2, :week},
    remember_token_length: 16,
    remember_cookie_name: "remember_token",
    remember_cookie_options: [
      #domain:
      #max_age:
      #path:
      http_only: true
      #secure:
      #extra:
    ]
  ]

  @impl Haytni.Plugin
  def files_to_install do
    import Mix.Tasks.Haytni.Install, only: [web_path: 0, timestamp: 0]
    [
      {:eex, "migrations/rememberable_changes.ex", Path.join([web_path(), "..", "..", "priv", "repo", "migrations", "#{timestamp()}_haytni_rememberable_changes.ex"])} # TODO: less "hacky"
    ]
  end

  @impl Haytni.Plugin
  def fields do
    quote do
      field :remember_token, :string, default: nil # NULLABLE, UNIQUE
      field :remember_created_at, :utc_datetime, default: nil # NULLABLE
    end
  end

  @doc ~S"""
  Returns if this plugin is enabled.
  """
  def enabled? do
    __MODULE__ in Haytni.plugins()
  end

if false do
  @spec authentificate_by_token(token :: String.t) :: {:ok, struct} | {:error, atom}
  defp authentificate_by_token(token) do
    Haytni.Users.get_user_by(token: token)
  end
end

  @impl Haytni.Plugin
  def find_user(conn = %Plug.Conn{}) do
    token = Map.get(conn.cookies, remember_cookie_name())
    if token do
      case Phoenix.Token.verify(conn, remember_salt(), token, max_age: Haytni.duration(remember_for())) do
        {:ok, remember_token} ->
          # we shouldn't need
          # AND remember_created_at <= NOW() + INTERVAL remember_for()
          # as Phoenix.Token.verify discards expired token
          {conn, Haytni.Users.get_user_by(remember_token: remember_token)}
        _ ->
          {remove_rememberme_cookie(conn), nil}
      end
    else
      {conn, nil}
    end
  end

  @impl Haytni.Plugin
  # The checkbox "remember me" is checked (present in params)
  def on_successful_authentification(conn = %Plug.Conn{params: %{"remember" => _}}, user = %_{}, keyword) do
    {remember_token, keyword} = if rememberable_token_expired?(user) do
      remember_token = remember_token_length()
      |> Haytni.Token.generate()
      keyword = keyword
      |> Keyword.put(:remember_created_at, DateTime.utc_now())
      |> Keyword.put(:remember_token, remember_token)
      {remember_token, keyword}
    else
      {user.remember_token, keyword}
    end
    token = Phoenix.Token.sign(conn, remember_salt(), remember_token)
    conn = put_resp_cookie(conn, remember_cookie_name(), token, remember_cookie_options_with_max_age())
    {conn, user, keyword}
  end

  # The checkbox "remember me" is not checked (absent from params)
  def on_successful_authentification(conn = %Plug.Conn{}, user = %_{}, keyword) do
    {conn, user, keyword}
  end

  @spec rememberable_token_expired?(user :: struct) :: boolean
  defp rememberable_token_expired?(user) do
    DateTime.diff(DateTime.utc_now(), user.remember_created_at) >= Haytni.duration(remember_for())
  end

  defp remove_rememberme_cookie(conn = %Plug.Conn{}) do
    conn
    |> delete_resp_cookie(remember_cookie_name(), remember_cookie_options_with_max_age())
  end

  defp remember_cookie_options_with_max_age do
    remember_cookie_options()
    |> Keyword.put_new(:max_age, Haytni.duration(remember_for()))
  end

  @impl Haytni.Plugin
  def on_logout(conn = %Plug.Conn{}) do
    conn
    |> remove_rememberme_cookie()
  end
end
