defmodule Haytni.Users do
  import Ecto.Query, warn: false

  defp repo do
    Haytni.repo()
  end

  defp schema do
    Haytni.schema()
  end

  def struct do
    schema()
    |> struct()
  end

  def list_users do
    repo = repo()
    schema()
    |> repo.all()
  end

  @doc ~S"""
  Fetches a single user from the data store where the primary key matches the given id.

  Returns `nil` if no result was found. If the struct in the queryable has no or more than one primary key, it will raise an argument error.
  """
  @spec get_user(id :: term) :: Haytni.user | nil | no_return
  def get_user(id) do
    repo = repo()
    schema()
    |> repo.get(id)
  end

  @doc ~S"""
  Same as `get_user/1` but raises `Ecto.NoResultsError` if no user was found.
  """
  @spec get_user!(id :: term) :: Haytni.user | no_return
  def get_user!(id) do
    repo = repo()
    schema()
    |> repo.get!(id)
  end

  @doc ~S"""
  Fetches a single user from key/value pairs (Keyword or map).

  Returns `nil` if no one matches.
  """
  @spec get_user_by(clauses :: Keyword.t | map) :: Haytni.user | nil
  def get_user_by(clauses) do
    schema()
    |> repo().get_by(clauses)
  end

if false do
  @doc """
    Options:

    * `:with` - the changeset/2 function, in the form `{module, function}`, to build the changeset from params. Defaults to `{schema(), :changeset}`
  """
  @spec create_user(attrs :: map, opts :: Keyword.t) :: {:ok, Haytni.user} | {:error, Ecto.Changeset.t}
  def create_user(attrs = %{}, opts \\ []) do
    {m, f} = Keyword.get(opts, :with, {schema(), :changeset})
    apply(m, f, [struct(), attrs])
    |> repo().insert()
  end

  @doc """
    Options:

    * `:with` - the changeset/2 function, in the form `{module, function}`, to build the changeset from params. Defaults to `{schema(), :changeset}`
  """
  @spec update_user(user :: Haytni.user, attrs :: map, opts :: Keyword.t) :: {:ok, Haytni.user} | {:error, Ecto.Changeset.t}
  def update_user(user = %_{}, attrs = %{}, opts \\ []) do
    {m, f} = Keyword.get(opts, :with, {schema(), :changeset})
    apply(m, f, [user, attrs])
    |> repo().update()
  end
end

  def delete_user(user = %_{}) do
    repo().delete(user)
  end

  def change_user do
    struct()
    |> change_user()
  end

  def change_user(user = %_{}) do
    schema().changeset(user, %{})
  end
end
