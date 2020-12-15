defmodule Haytni.Multi do
  @moduledoc ~S"""
  TODO (doc)
  """

  @doc ~S"""
  TODO (doc)
  """
  @spec assign(multi :: Ecto.Multi.t, name :: Ecto.Multi.name, data :: any) :: Ecto.Multi.t
  def assign(multi = %Ecto.Multi{}, name, data) do
    Ecto.Multi.run(multi, name, fn _repo, _changes -> {:ok, data} end)
  end

  #defp struct_to_query(struct = %module{}) do
    #import Ecto.Query

    #where =
      #:primary_key
      #|> module.__schema__()
      #|> Enum.into([], fn field -> {field, Map.fetch!(struct, field)} end)

    #module
    #|> where(^where)
  #end

  @doc ~S"""
  TODO (doc + test)

  ```elixir
  defmodule MyApp.Post do
    schema "posts" do
      field :comments_count, :integer, default: 0

      has_many :comments, MyApp.Comment
    end
  end

  defmodule MyApp.Comment do
    schema "comments" do
      belongs_to :user, MyApp.User
      belongs_to :post, MyApp.Post
    end

    def changeset(comment = %__MODULE__{}, user = %MyApp.User{}, post = %MyApp.Post{}, attrs = %{}) do
      comment
      |> Ecto.Changeset.cast(attrs, [...])
      |> Ecto.Changeset.put_assoc(:user, user)
      |> Ecto.Changeset.put_assoc(:post, post)
      # ... additional validations ...
    end
  end

  def create_comment(user = %MyApp.User{}, post = %MyApp.Post{}, params = %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:comment, MyApp.Comment.changeset(%MyApp.Comment{}, user, post, params))
    |> Haytni.Multi.counter_cache_increment(
      :increment_comments_count, # name of the operation (whatever you like)
      :comment, # same name as the first argument of the Ecto.Multi.insert above
      :post, # name of the parent association (ie the value of the first argument of `belongs_to`)
      :comments_count # name of the field to increment
    )
    |> MyApp.Repo.transaction()
  end
  ```
  """
  @spec counter_cache_increment(multi :: Ecto.Multi.t, name :: Ecto.Multi.name, struct_name :: Ecto.Multi.name, assoc :: atom, field :: atom) :: Ecto.Multi.t
  def counter_cache_increment(multi = %Ecto.Multi{}, name, struct_name, assoc, field) do
    Ecto.Multi.update_all(
      multi,
      name,
      fn %{^struct_name => struct} ->
        import Ecto.Query

        #q =
          #struct
          #|> struct_to_query

        #from(q, inc: [{field, 1}])
        from(Ecto.assoc(struct, assoc), update: [inc: [{^field, 1}]])
      end,
      []
    )
  end

  @doc ~S"""
  TODO (doc)
  """
  @spec select(multi :: Ecto.Multi.t, name :: Ecto.Multi.name, query :: Ecto.Query.t, error_value :: any) :: Ecto.Multi.t
  def select(multi = %Ecto.Multi{}, name, query, error_value) do
    Ecto.Multi.run(
      multi,
      name,
      fn repo, _changes ->
        case repo.get(query) do
          nil ->
            {:error, error_value}
          struct = %_{} ->
            {:ok, struct}
        end
      end
    )
  end

  @doc ~S"""
  TODO (doc)
  """
  # name => {:ok, map | struct) | {:error, %Ecto.Changeset.t}
  @spec apply_changeset(multi :: Ecto.Multi.t, name :: Ecto.Multi.name, changeset :: Ecto.Changeset.t) :: Ecto.Multi.t
  def apply_changeset(multi = %Ecto.Multi{}, name, changeset = %Ecto.Changeset{}) do
    Ecto.Multi.run(
      multi,
      name,
      fn _repo, _changes ->
        Ecto.Changeset.apply_action(changeset, :insert)
      end
    )
  end

  @doc ~S"""
  TODO (doc)
  """
  @spec apply_base_error(multi :: Ecto.Multi.t, name :: Ecto.Multi.name, changeset :: Ecto.Changeset.t, message :: String.t) :: Ecto.Multi.t
  def apply_base_error(multi = %Ecto.Multi{}, name, changeset = %Ecto.Changeset{}, message) do
if true do
    {:error, changeset} = Haytni.Helpers.apply_base_error(changeset, message)
    Ecto.Multi.error(multi, name, changeset)
else
    Ecto.Multi.run(
      multi,
      name,
      fn _repo, _changes ->
        Haytni.Helpers.apply_base_error(changeset, message)
      end
    )
end
  end

  @doc ~S"""
  TODO (doc)
  """
  @spec get_user(multi :: Ecto.Multi.t, module :: module, user_name :: Ecto.Multi.name, params_name :: Ecto.Multi.name, conditions :: Ecto.Query.t) :: Ecto.Multi.t
  def get_user(multi = %Ecto.Multi{}, user_name, module, params_name, conditions \\ true) do
    Ecto.Multi.run(
      multi,
      user_name,
      fn repo, %{^params_name => sanitized_params} ->
        import Ecto.Query

        from(
          u in module.schema(),
          where: ^Map.to_list(Map.delete(sanitized_params, :referer)),
          where: ^conditions
        )
        |> repo.one()
        |> case do
          nil ->
            # TODO: renvoyer un (le) changeset avec :base ou les clés marquées comme non correspondance
            # - argument lazy ? fn -> Haytni.Helpers.apply_base_error(changeset, "message") end
            {:error, :no_result} # renvoyer {:ok, nil}, ce qui irait dans le sens du "mode strict" ?
          struct = %_{} ->
            {:ok, struct}
        end
      end
    )
  end

  @doc ~S"""
  TODO (doc)
  """
  @spec get_user_by(multi :: Ecto.Multi.t, module :: module, user_name :: Ecto.Multi.name, params_name :: Ecto.Multi.name) :: Ecto.Multi.t
  def get_user_by(multi = %Ecto.Multi{}, user_name, module, params_name) do
    Ecto.Multi.run(
      multi,
      user_name,
      fn repo, %{^params_name => sanitized_params} ->
        case repo.get_by(module.schema(), Map.delete(sanitized_params, :referer)) do
          nil ->
            {:error, :no_result} # TODO
          struct = %_{} ->
            {:ok, struct}
        end
      end
    )
  end

  @doc ~S"""
  TODO (doc)

  (doublon de Haytni.Token.insert_token_in_multi)
  """
  @spec insert_token(multi :: Ecto.Multi.t, token_name :: Ecto.Multi.name, user_name :: Ecto.Multi.name, context :: String.t) :: Ecto.Multi.t
  def insert_token(multi = %Ecto.Multi{}, token_name, user_name, context) do
    Ecto.Multi.insert(
      multi,
      token_name,
      fn %{^user_name => user} ->
        # TODO: if user != nil ?
        Haytni.Token.build_and_assoc_token(user, user.email, context)
      end
    )
  end

  @doc ~S"""
  TODO (doc)
  """
  @spec delete_tokens(multi :: Ecto.Multi.t, deletion_name :: Ecto.Multi.name, user_name :: Ecto.Multi.name, contexts :: String.t | nonempty_list(String.t) | :all) :: Ecto.Multi.t
  def delete_tokens(multi = %Ecto.Multi{}, deletion_name, user_name, contexts) do
    Ecto.Multi.delete_all(
      multi,
      deletion_name,
      fn %{^user_name => user} ->
        Haytni.Token.tokens_from_user_query(user, contexts)
      end
    )
  end

  @doc ~S"""
  TODO: doublon avec Haytni.update_user_in_multi_with

  Update user in the same way as `Haytni.update_user_with/3` but as part of a set of operations (Ecto.Multi).
  """
  @spec update_user_with(multi :: Ecto.Multi.t, name :: Ecto.Multi.name, user :: Haytni.user, changes :: Keyword.t) :: Ecto.Multi.t
  def update_user_with(multi = %Ecto.Multi{}, name, user = %_{}, changes) do
    Ecto.Multi.update(multi, name, Haytni.user_and_changes_to_changeset(user, changes))
  end
end
