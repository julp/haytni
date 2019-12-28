defmodule HaytniTest.Users do
  import Ecto.Query, warn: false

  alias HaytniTest.Repo

  def list_users do
    HaytniTest.User
    |> Repo.all()
  end

  @doc ~S"""
  Fetches a single user from the data store where the primary key matches the given id.

  Returns `nil` if no result was found. If the struct in the queryable has no or more than one primary key, it will raise an argument error.
  """
  @spec get_user(id :: term) :: Haytni.user | nil | no_return
  def get_user(id) do
    HaytniTest.User
    |> Repo.get(id)
  end

  @doc ~S"""
  Same as `get_user/1` but raises `Ecto.NoResultsError` if no user was found.
  """
  @spec get_user!(id :: term) :: Haytni.user | no_return
  def get_user!(id) do
    HaytniTest.User
    |> Repo.get!(id)
  end

  @doc ~S"""
  Fetches a single user from key/value pairs (Keyword or map).

  Returns `nil` if no one matches.
  """
  @spec get_user_by(clauses :: Keyword.t | map) :: Haytni.user | nil
  def get_user_by(clauses) do
    HaytniTest.User
    |> Repo.get_by(clauses)
  end

  def delete_user(user = %_{}) do
    Repo.delete(user)
  end

  def change_user do
    HaytniTest.User
    |> change_user()
  end

  def change_user(user = %_{}) do
    HaytniTest.User.changeset(user, %{})
  end
end
