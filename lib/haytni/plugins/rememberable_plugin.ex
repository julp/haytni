defmodule Haytni.RememberablePlugin do
  @default_remember_for {2, :week}
  @default_remember_cookie_name "remember_token"
  @default_remember_cookie_options [
    http_only: true,
    extra: "SameSite=Strict",
  ]

  @moduledoc """
  This plugin makes artificialy last user's authentication by creating a cookie which stores a token for remembering the user.

  This cookie is cleared when user's manually logout.

  Configuration:

    * `remember_for` (default: `#{inspect(@default_remember_for)}`): the period of validity of the token/which the user won't be asked for credentials
    * `remember_cookie_name` (default: `#{inspect(@default_remember_cookie_name)}`): the name of the cookie holding the token for automatic sign in
    * `remember_cookie_options` (default: `#{inspect(@default_remember_cookie_options)}`): to set custom options of the cookie (options are: *domain*, *max_age*, *path*, *http_only*, *secure* and *extra*, see documentation of `Plug.Conn.put_resp_cookie/4`)

          stack #{inspect(__MODULE__)},
            remember_for: #{inspect(@default_remember_for)},
            remember_cookie_name: #{inspect(@default_remember_cookie_name)},
            remember_cookie_options: #{inspect(@default_remember_cookie_options)}

  Routes: none
  """

  defmodule Config do
    defstruct remember_for: {2, :week},
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
      remember_for: Haytni.duration,
      remember_cookie_name: String.t,
      remember_cookie_options: Keyword.t,
    }
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %Haytni.RememberablePlugin.Config{}
    |> Haytni.Helpers.merge_config(options, ~W[remember_for]a)
  end

  @impl Haytni.Plugin
  def find_user(conn = %Plug.Conn{}, module, config) do
#IO.puts("#{__MODULE__}.find_user") # TODO: removal/test
    conn = Plug.Conn.fetch_cookies(conn, signed: [config.remember_cookie_name])
    with(
      {:ok, token} <- Map.fetch(conn.cookies, config.remember_cookie_name),
      {:ok, rememberable_token} <- Haytni.Token.url_decode(token),
      user when not is_nil(user) <- Haytni.Token.user_from_token_with_mail_match(module, rememberable_token, token_context(nil), config.remember_for)
    ) do
      {conn, user}
    else
      _ ->
        {remove_rememberme_cookie(conn, config), nil}
    end
  end

  @impl Haytni.Plugin
  # The checkbox "remember me" is checked (present in params)
  # NOTE: it isn't necessary to check if the client has already one, if he goes through the authentication form, he obviously has not
  def on_successful_authentication(conn = %Plug.Conn{params: %{"session" => %{"remember" => _}}}, user = %_{}, multi = %Ecto.Multi{}, keyword, _module, config) do
    token = Haytni.Token.build_and_assoc_token(user, user.email, token_context(nil))

    {add_rememberme_cookie(conn, Haytni.Token.url_encode(token), config), Ecto.Multi.insert(multi, :rememberable_token, token), keyword}
  end

  # The checkbox "remember me" is not checked (absent from params)
  def on_successful_authentication(conn = %Plug.Conn{}, _user = %_{}, multi = %Ecto.Multi{}, keyword, _module, _config) do
    {conn, multi, keyword}
  end

  use Haytni.Tokenable

  @impl Haytni.Tokenable
  def token_context(nil) do
    "rememberable"
  end

  @impl Haytni.Tokenable
  def expired_tokens_query(query, config) do
    import Ecto.Query

    from(
      t in query,
      or_where: t.context == ^token_context(nil) and t.inserted_at > ago(^config.remember_for, "second")
    )
  end

  @doc ~S"""
  Sign *remember_token* then add it to *conn* response's cookies.

  Returns the updated `%Plug.Conn{}` with our rememberme cookie
  """
  @spec add_rememberme_cookie(conn :: Plug.Conn.t, remember_token :: String.t, config :: Config.t) :: Plug.Conn.t
  def add_rememberme_cookie(conn = %Plug.Conn{}, remember_token, config) do
    conn
    |> Plug.Conn.put_resp_cookie(config.remember_cookie_name, remember_token, remember_cookie_options_with_max_age(config))
  end

  @spec remove_rememberme_cookie(conn :: Plug.Conn.t, config :: Config.t) :: Plug.Conn.t
  defp remove_rememberme_cookie(conn = %Plug.Conn{}, config) do
    Plug.Conn.delete_resp_cookie(conn, config.remember_cookie_name, remember_cookie_options_with_max_age(config))
  end

  @spec remember_cookie_options_with_max_age(config :: Config.t) :: Keyword.t
  defp remember_cookie_options_with_max_age(config) do
    config.remember_cookie_options
    |> Keyword.put_new(:sign, true)
    |> Keyword.put_new(:max_age, config.remember_for)
  end

  @impl Haytni.Plugin
  def on_logout(conn = %Plug.Conn{}, _module, config) do
    remove_rememberme_cookie(conn, config)
  end
end
