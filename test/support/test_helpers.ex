defmodule Haytni.TestHelpers do
  alias Haytni.Params
  import ExUnit.Assertions

  @type falsy :: false | nil

  @spec fixture(attrs :: Enumerable.t, schema :: module) :: Haytni.user
  defp fixture(attrs, schema) do
    id = System.unique_integer([:positive])
    config = HaytniTestWeb.Haytni.fetch_config(Haytni.AuthenticablePlugin)

    attrs =
      attrs
      |> Enum.into(
        %{
          email: "test#{id}@test.com",
          password: attrs[:password] || "not so SECRET!",
        }
      )
    attrs = Map.put(attrs, :encrypted_password, Haytni.AuthenticablePlugin.hash_password(attrs.password, config))

    {:ok, user} =
      schema
      |> struct(attrs)
      |> HaytniTest.Repo.insert()

    user
  end

  @doc ~S"""
  On the fly creation of an Elixir module from an EEx template
  """
  @spec onfly_module_from_eex(path :: String.t, binding :: Keyword.t) :: module
  def onfly_module_from_eex(path, binding) do
    [{module, _binary}] =
      path
      |> EEx.eval_file(binding)
      |> Code.compile_string()
    module
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
        %{route: ^route, plug: ^controller, plug_opts: ^action} = Phoenix.Router.route_info(router, method, route, "test.com")
      end
    )
  end

  @doc ~S"""
  Creates a user with the following attributes:

    * `"notasecret"` as password by default
    * an auto-generated email address unless one is specified in *attrs*
    * the password is automatically hashed, no need to handle this aspect

  Any field can be overridden with the appropriate key in *attrs*

  Example:

      iron_man = user_fixture(email: "tony.stark@stark-industries.com", firstname: "Tony", lastname: "Stark")
  """
  @spec user_fixture(attrs :: Enumerable.t) :: Haytni.user
  def user_fixture(attrs \\ %{}) do
    fixture(attrs, HaytniTest.User)
  end

  @doc ~S"""
  Same as `user_fixture/1` but returns a `%HaytniTest.Admin{}` instead of a `%HaytniTest.User{}`
  """
  @spec admin_fixture(attrs :: Enumerable.t) :: Haytni.user
  def admin_fixture(attrs \\ %{}) do
    fixture(attrs, HaytniTest.Admin)
  end

  @doc ~S"""
  Creates a token associated to *user* and with the value returned by plugin.token_context/1 as context
  (if not overridden by *:context* key in attributes).

  The following attributes are supported:

    * sent_to (default: `user.email`): the email address the token was sent to
    * inserted_at (default: `0`): the number of seconds ago the token has been generated
    * token (default: some random string): the raw token
    * context (default: `plugin.token_context(nil)`): the context associated to the token
  """
  @spec token_fixture(user :: Haytni.user, plugin :: module, attrs :: Keyword.t) :: Haytni.Token.t
  def token_fixture(user, plugin, attrs \\ []) do
    sent_to = Keyword.get(attrs, :sent_to, user.email)
    inserted_at = Keyword.get(attrs, :inserted_at, 0)
    context = Keyword.get(attrs, :context, plugin.token_context(nil))
    token = Keyword.get_lazy(attrs, :token, fn -> Haytni.Token.new(16) end)

    {:ok, token} =
      user
      |> Ecto.build_assoc(:tokens, token: token, context: context, sent_to: sent_to, inserted_at: seconds_ago(inserted_at))
      |> HaytniTest.Repo.insert()

    token
  end

  @doc ~S"""
  Creates an invitation from *user* to *sent_to* email address.

  Optional attributes:

    * `:code` (String.t): use the given code instead of generating one
    * `:sent_at` (integer): dated from *sent_at* seconds ago from now (to test expiration)
    * `:accepted_by` (struct or integer or nil): the id of the user who accepted the invitation (`nil` if unused)
  """
  @spec invitation_fixture(user :: Haytni.user, sent_to :: String.t, attrs :: Keyword.t) :: Haytni.InvitablePlugin.invitation
  def invitation_fixture(user, sent_to, attrs \\ []) do
    sent_at = Keyword.get(attrs, :sent_at, 0)
    code = Keyword.get_lazy(attrs, :code, fn -> Haytni.InvitablePlugin.random_code(16) end)
    accepter_id = case Keyword.get(attrs, :accepted_by, nil) do
      %_{id: id} when is_integer(id) ->
        id
      other when is_nil(other) or is_integer(other) ->
        other
    end

    {:ok, invitation} =
      user
      |> Haytni.InvitablePlugin.build_and_assoc_invitation(code: code, sent_at: seconds_ago(sent_at), sent_to: sent_to, accepted_by: accepter_id)
      |> HaytniTest.Repo.insert()

    invitation
  end

  @doc ~S"""
  Returns the list of all invitations (accepted as pending) send by the provided user
  """
  @spec list_invitations(module :: module, user :: Haytni.user) :: [Haytni.InvitablePlugin.invitation]
  def list_invitations(module, user) do
    user
    |> Haytni.InvitablePlugin.QueryHelpers.invitations_from_user()
    |> module.repo().all()
  end

  @doc ~S"""
  Creates the parameters to simulate a temporary sign in action.

  Example:

      iex> session_params_without_rememberme(%{"email" => "foo@bar.com", "password" => "azerty"})
      %{"session" => %{"email" => "foo@bar.com", "password" => "azerty"}}
  """
  @spec session_params_without_rememberme(attrs :: Enumerable.t | struct) :: Haytni.params
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
    html =
      text
      |> Phoenix.HTML.Format.text_to_html()
      |> Phoenix.HTML.safe_to_string()
      |> IO.iodata_to_binary()

    response =~ html
  end

  defp max_age(config) do
    case Keyword.fetch(config.remember_cookie_options, :max_age) do
      {:ok, value} ->
        [max_age: value]
      :error ->
        []
    end
  end

  @doc ~S"""
  Adds the rememberme cookie to the HTTP request by signing the remember *token* (for the Rememberable plugin)
  """
  @spec add_rememberme_cookie(conn :: Plug.Conn.t, token :: String.t, config :: Haytni.config) :: Plug.Conn.t
  def add_rememberme_cookie(conn = %Plug.Conn{}, token, config) do
    signed_token = Plug.Crypto.sign(conn.secret_key_base, config.remember_cookie_name <> "_cookie", token, max_age(config))
    Phoenix.ConnTest.put_req_cookie(conn, config.remember_cookie_name, signed_token)
  end

  @doc ~S"""
  Ensures the rememberme cookie (from the Rememberable plugin) is:

    1. present (name: `config.remember_cookie_name`)
    2. expires (its max age) at least in `config.remember_for` seconds from now
    3. its signed value match (the rememberable) *token*
  """
  @spec assert_rememberme_presence(conn :: Plug.Conn.t, config :: Haytni.RememberablePlugin.Config.t, token :: String.t) :: {:ok, String.t}
  def assert_rememberme_presence(conn, config, token) do
    conn = Plug.Conn.fetch_cookies(conn, signed: [config.remember_cookie_name])
    {:ok, cookie} = Map.fetch(conn.resp_cookies, config.remember_cookie_name)
    true = DateTime.diff(DateTime.from_unix!(cookie.max_age), DateTime.utc_now()) >= config.remember_for
    {:ok, ^token} = Plug.Crypto.verify(conn.secret_key_base, config.remember_cookie_name <> "_cookie", cookie.value, max_age(config))
  end

  @doc ~S"""
  Asserts the server requested the deletion of the cookie named *name* to the client in the HTTP response.
  """
  @spec assert_cookie_deletion(conn :: Plug.Conn.t, name :: String.t) :: falsy | no_return
  def assert_cookie_deletion(conn, name) do
    conn = Plug.Conn.fetch_cookies(conn, signed: [name])
    cookie = Map.get(conn.resp_cookies, name)

    # NOTE: keep in mind that when you want to delete a cookie, you (the server) send a Set-Cookie
    # header with the same name but without value and an expiration date in the past!
    %{max_age: 0, universal_time: {{1970, 1, 1}, {0, 0, 0}}} = cookie
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

  @doc ~S"""
  Generates a random string composed of *len* letters (only
  to be a valid component of a module name)
  """
  # Borrowed to phoenix (phoenix/installer/test/mix_helper.exs)
  @spec random_string(len :: non_neg_integer) :: String.t
  def random_string(len) do
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIKLMNOPQRSTUVWXYZ'
    |> Enum.shuffle()
    |> Enum.take(len)
    |> to_string()
  end

  @doc ~S"""
  Creates a temporary directory, its path is the concatenation of `System.tmp_dir!/1`
  <> *which* <> a small random generated string then temporarily changes the currect
  working directory to it, the time to execute *fun/0*

  NOTE: changing current directory has side effects so you can't declare your test
  `async: true`.
  """
  # Borrowed to phoenix (phoenix/installer/test/mix_helper.exs)
  @spec in_tmp_project(which :: String.t, fun :: (-> any)) :: :ok
  def in_tmp_project(which, fun) do
    root = Path.join([System.tmp_dir!(), which, random_string(10)])
    try do
      File.rm_rf!(root)
      File.mkdir_p!(root)
      File.cd!(
        root,
        fn ->
          #File.touch!("mix.exs")
          fun.()
        end
      )
    after
      File.rm_rf!(root)
    end
    :ok
  end

  @doc ~S"""
  Asserts a (regular) file exists.
  """
  @spec assert_file(file :: String.t) :: true | no_return
  # Borrowed to phoenix (phoenix/installer/test/mix_helper.exs)
  def assert_file(file) do
    assert File.regular?(file), "Expected #{file} to exist, but does not"
  end

  @doc ~S"""
  Asserts a file does not exist or is not a regular file.
  """
  @spec refute_file(file :: String.t) :: false | no_return
  # Borrowed to phoenix (phoenix/installer/test/mix_helper.exs)
  def refute_file(file) do
    refute File.regular?(file), "Expected #{file} to not exist, but it does"
  end

  @doc ~S"""
  Asserts that *file* is a regular file and also checks its content.

  *match* can be:
  * a list of patterns (strings or regexpes) to be matched by *file* content
  * a string or regexp to be found in *file*
  * a function of arity 1 to be called with the content of the file
  """
  # Borrowed to phoenix (phoenix/installer/test/mix_helper.exs)
  @type match :: [String.t | Regex.t] | String.t | Regex.t | (String.t -> any | no_return)
  @spec assert_file(file :: String.t, match :: match) :: any | no_return
  def assert_file(file, match) do
    cond do
      is_list(match) ->
        assert_file file, &(Enum.each(match, fn(m) -> assert &1 =~ m end))
      is_binary(match) or Regex.regex?(match) ->
        assert_file file, &(assert &1 =~ match)
      is_function(match, 1) ->
        assert_file(file)
        match.(File.read!(file))
      true -> raise inspect({file, match})
    end
  end
end
