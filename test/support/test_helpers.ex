defmodule Haytni.TestHelpers do
  alias Haytni.Params
  import ExUnit.Assertions

  @type falsy :: false | nil

  @spec fixture(attrs :: Enumerable, schema :: module) :: Haytni.user
  defp fixture(attrs, schema) do
    id = System.unique_integer([:positive])
    config = HaytniTestWeb.Haytni.fetch_config(Haytni.AuthenticablePlugin)

    attrs = attrs
    |> Enum.into(
      %{
        email: "test#{id}@test.com",
        confirmation_sent_at: Haytni.Helpers.now(),
        password: attrs[:password] || "not so SECRET!",
      }
    )
    attrs = Map.put(attrs, :encrypted_password, config.password_hash_fun.(attrs.password))

    {:ok, user} = schema
    |> struct(attrs)
    |> HaytniTest.Repo.insert()

    user
  end

  @doc ~S"""
  Ensures all given *routes* are handled by *router*

  Example:

      [
        %{route: "/avatar/new", method: "GET", action: :new, controller: MyAppWeb.AvatarController},
        %{route: "/avatar", method: "POST", action: :create, controller: MyAppWeb.AvatarController},
        %{route: "/avatar", method: "DELETE", action: :delete, controller: MyAppWeb.AvatarController},
      ]
      |> check_routes(MyAppWeb.Router)
  """
  @spec check_routes(routes :: [%{route: String.t, method: String.t, action: atom, controller: module}], router :: module) :: :ok | no_return
  def check_routes(routes, router) do
    Enum.each(
      routes,
      fn %{route: route, method: method, action: action, controller: controller} ->
        assert %{route: ^route, plug: ^controller, plug_opts: ^action} = Phoenix.Router.route_info(router, method, route, "test.com")
      end
    )
  end

  @doc ~S"""
  Creates a user with the following attributes:

    * confirmed
    * `"notasecret"` as password by default
    * an auto-generated email address unless one is specified in *attrs*
    * the password is automatically hashed, no need to handle this aspect

  Any field can be overridden with the appropriate key in *attrs*

  Example:

      iron_man = user_fixture(email: "tony.stark@stark-industries.com", firstname: "Tony", lastname: "Stark")
  """
  @spec user_fixture(attrs :: Enumerable) :: Haytni.user
  def user_fixture(attrs \\ %{}) do
    fixture(attrs, HaytniTest.User)
  end

  @doc ~S"""
  Same as `user_fixture/1` but returns a `%HaytniTest.Admin{}` instead of a `%HaytniTest.User{}`
  """
  @spec user_fixture(attrs :: Enumerable) :: Haytni.user
  def admin_fixture(attrs \\ %{}) do
    fixture(attrs, HaytniTest.Admin)
  end

  @doc ~S"""
  Creates the parameters to simulate a temporary sign in action.

  Example:

      iex> session_params_without_rememberme(%{"email" => "foo@bar.com", "password" => "azerty"})
      %{"session" => %{"email" => "foo@bar.com", "password" => "azerty"}}
  """
  @spec session_params_without_rememberme(attrs :: Enumerable | struct) :: %{String.t => String.t}
  def session_params_without_rememberme(attrs \\ %{}) do
    [
      email: "abc@def.ghi",
      password: "not a secret",
      #remember: "checked",
    ]
    |> Params.create(attrs)
    |> Params.wrap(:session)
  end

  @doc ~S"""
  The message set by default by `Ecto.Changeset.validate_required/3` as error
  """
  @spec empty_message() :: String.t
  def empty_message do
    "can't be blank"
  end

  @doc ~S"""
  The message set by default by `Ecto.Changeset.unique_constraint/3` as error
  """
  @spec already_took_message() :: String.t
  def already_took_message do
    "has already been taken"
  end

  @doc ~S"""
  The message set by default by `Ecto.Changeset.validate_format/4` as error
  """
  @spec invalid_format_message() :: String.t
  def invalid_format_message do
    "has invalid format"
  end

  @doc ~S"""
  The message set by default by `Ecto.Changeset.validate_confirmation/3` as error
  """
  @spec confirmation_mismatch_message() :: String.t
  def confirmation_mismatch_message do
    "does not match confirmation"
  end

  @doc """
  Returns `true` if *response* contains the HTML escaped string *text*

  Example:

      iex> #{__MODULE__}.contains_text?("password doesn&#39;t match", "doesn't match")
      true
  """
  @spec contains_text?(response :: String.t, text :: String.t) :: boolean
  def contains_text?(response, text) do
    String.contains?(response, Plug.HTML.html_escape(text))
  end

  @doc ~S"""
  Returns `true` if *response* contains the HTML code resulting in applying
  `Phoenix.HTML.Format.text_to_html/1` to *text*.
  """
  @spec contains_formatted_text?(response :: String.t, text :: String.t) :: boolean
  def contains_formatted_text?(response, text) do
    html = text
    |> Phoenix.HTML.Format.text_to_html()
    |> Phoenix.HTML.safe_to_string()
    |> IO.iodata_to_binary()

    String.contains?(response, html)
  end

  @doc ~S"""
  Adds the rememberme cookie to the HTTP request by signing the remember *token* (for the Rememberable plugin)
  """
  @spec add_rememberme_cookie(conn :: Plug.Conn.t, token :: String.t, config :: Haytni.config) :: Plug.Conn.t
  def add_rememberme_cookie(conn = %Plug.Conn{}, token, config) do
    signed_token = Haytni.RememberablePlugin.sign_token(conn, token, config)
    Phoenix.ConnTest.put_req_cookie(conn, config.remember_cookie_name, signed_token)
  end

  @doc ~S"""
  Asserts the server requested the deletion of the cookie named *name* to the client in the HTTP response.
  """
  @spec assert_cookie_deletion(conn :: Plug.Conn.t, name :: String.t) :: falsy | no_return
  def assert_cookie_deletion(conn, name) do
    cookie = Map.get(conn.resp_cookies, name)

    # NOTE: keep in mind that when you want to delete a cookie, you (the server) send a Set-Cookie
    # header with the same name but without value and an expiration date in the past!
    assert %{max_age: 0, universal_time: {{1970, 1, 1}, {0, 0, 0}}} = cookie
    refute Map.has_key?(cookie, :value)
  end

  @doc ~S"""
  Refutes any presence of the cookie named *name*
  """
  @spec refute_cookie_presence(conn :: Plug.Conn.t, name :: String.t) :: falsy | no_return
  def refute_cookie_presence(conn, name) do
    refute Map.has_key?(conn.resp_cookies, name)
  end

  @doc ~S"""
  Ensures the rememberme cookie (from the Rememberable plugin) is:

    1. present (name: `config.remember_cookie_name`)
    2. expires (its max age) at least in `config.remember_for` seconds from now
    3. its signed value match (the rememberable) *token*
  """
  @spec assert_rememberme_presence(conn :: Plug.Conn.t, config :: Haytni.RememberablePlugin.Config.t, token :: String.t) :: {:ok, String.t}
  def assert_rememberme_presence(conn, config, token) do
    {:ok, cookie} = Map.fetch(conn.resp_cookies, config.remember_cookie_name)
    true = DateTime.diff(DateTime.from_unix!(cookie.max_age), DateTime.utc_now()) >= config.remember_for
    {:ok, ^token} = Haytni.RememberablePlugin.verify_token(conn, cookie.value, config)
  end

  @doc ~S"""
  Returns a DateTime for *seconds* seconds ago from now
  """
  @spec seconds_ago(seconds :: integer) :: DateTime.t
  def seconds_ago(seconds) do
    DateTime.utc_now()
    |> DateTime.add(-seconds, :second)
    |> DateTime.truncate(:second)
  end

  @doc """
  Returns true if the list *a* contains at least all elements from *b*
  (any extra elements in *a* are ignored)

    iex> #{__MODULE__}.contains?(~W[a b c]a, ~W[a b]a)
    true

    iex> #{__MODULE__}.contains?(~W[a c]a, ~W[a b]a)
    false
  """
  @spec contains?(a :: [atom], b :: [atom]) :: boolean
  def contains?(a, b)
    when is_list(a) and is_list(b)
  do
    b
    |> MapSet.new()
    |> MapSet.subset?(MapSet.new(a))
  end
end
