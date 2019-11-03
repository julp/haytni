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
end
