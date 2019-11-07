defmodule Haytni.TestHelpers do
  def user_fixture(attrs \\ %{}) do
    id = System.unique_integer([:positive])

    attrs = attrs
    |> Enum.into(
      %{
        email: "test#{id}@test.com",
        password: attrs[:password] || "notasecret",
      }
    )

    {:ok, %{user: user = %HaytniTest.User{}}} = ~W[email password]a
    |> Enum.into(
      attrs,
      fn field ->
        {:"#{field}_confirmation", Map.get(attrs, field)}
      end
    )
    |> Haytni.create_user()

    user
  end

  @spec add_rememberme_cookie(conn :: Plug.Conn.t, token :: String.t) :: Plug.Conn.t
  def add_rememberme_cookie(conn = %Plug.Conn{}, token) do
    conn
    |> Phoenix.ConnTest.put_req_cookie(Haytni.RememberablePlugin.remember_cookie_name(), token)
  end

  @spec create_session(email :: String.t, password :: String.t) :: Haytni.Session.t
  def create_session(email, password) do
    {:ok, session} = Haytni.Session.create_session(%{email: email, password: password})

    session
  end

  @doc ~S"""
  Returns a DateTime for *seconds* seconds ago from now
  """
  def seconds_ago(seconds) do
    DateTime.utc_now()
    |> DateTime.add(-seconds, :second)
    |> DateTime.truncate(:second)
  end

  @doc """
  Returns true if the list *a* contains at least all elements from *b*
  (any extra elements in *a* are ignored)

    iex> #{__MODULE__}.contains(~W[a b c]a, ~W[a b]a)
    true

    iex> #{__MODULE__}.contains(~W[a c]a, ~W[a b]a)
    false
  """
  @spec contains(a :: [atom], b :: [atom]) :: boolean
  def contains(a, b)
    when is_list(a) and is_list(b)
  do
    b
    |> Enum.all?(
      fn v ->
        Enum.member?(a, v)
      end
    )
  end

  @spec lock_user!(user :: Haytni.user, unlock_token :: String.t) :: Haytni.user
  def lock_user!(user = %_{}, unlock_token) do
    user
    |> Ecto.Changeset.change(unlock_token: unlock_token, locked_at: ~U[1970-01-01 00:00:00Z], failed_attempts: 100)
    |> Haytni.repo().update!()
  end
end
