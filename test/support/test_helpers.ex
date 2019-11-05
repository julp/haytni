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
  end

  @doc """
  Returns true if the list *a* contains at least all elements from *b*
  (any extra elements in *a* are ignored)

    iex> #{__MODULE__}.contains(~W[a b c]a, ~W[a b]a)
    true

    iex> #{__MODULE__}.contains(~W[a c]a, ~W[a b]a)
    false
  """
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

  def lock_user!(user = %_{}, unlock_token) do
    user
    |> Ecto.Changeset.change(unlock_token: unlock_token, locked_at: ~U[1970-01-01 00:00:00Z], failed_attempts: 100)
    |> Haytni.repo().update!()
  end
end
