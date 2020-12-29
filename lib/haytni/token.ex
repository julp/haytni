defmodule Haytni.Token do
  @moduledoc ~S"""
  This module handles generation of tokens for the use of Haytni's plugins.
  """

  @type t :: struct

  @token_length 32
  @token_association :tokens

  import Ecto.Query

  @doc ~S"""
  Generates a *length* long random binary token
  """
  def new(length) do
    length
    |> :crypto.strong_rand_bytes()
  end

  @doc false
  def fields(_module) do
    quote do
      @after_compile Haytni.Token

      has_many unquote(@token_association), Haytni.Helpers.scope_module(__MODULE__, "Token"), foreign_key: :user_id # TODO: "#{scope}_id"?
    end
  end

  def __after_compile__(env, _bytecode) do
    contents = quote do
      use Ecto.Schema
      import Ecto.Changeset

      schema "#{unquote(env.module.__schema__(:source))}_tokens" do
        field :token, :binary # UNIQUE
        field :context, :string
        field :sent_to, :string # NULLABLE # utilisé par confirm/reset password que l'email entre les tables users et tokens (jointure) correspondent

        timestamps(updated_at: false, type: :utc_datetime)

        belongs_to :user, unquote(env.module), foreign_key: :user_id # TODO: "#{scope}_id"?
      end
    end

    Module.create(user_module_to_token_module(env.module), contents, env)
  end

  @doc ~S"""
  TODO (doc)

  NOTE: this is a "low level" function, the token is **NOT** persisted (designed to be used by Ecto.Multi)
  """
  @spec build_and_assoc_token(user :: Haytni.user, sent_to :: String.t, context :: String.t | atom) :: t
  def build_and_assoc_token(user = %_{}, sent_to, context) do
    Ecto.build_assoc(user, @token_association, token: new(@token_length), context: context, sent_to: sent_to)
  end

  @base64_options [padding: false]
  @doc ~S"""
  Encodes a token to safely figure in an URL
  """
  @spec encode_token(token :: t) :: String.t
  def encode_token(token = %_{}) do
    Base.url_encode64(token.token, @base64_options)
  end

  @doc ~S"""
  Decodes a token previously encoded by `encode_token/1`
  """
  @spec decode_token(token :: String.t) :: {:ok, String.t} | :error
  def decode_token(token) do
    Base.url_decode64(token, @base64_options)
  end

  if false do
    @hash_algorithm :sha256
    @spec hash_token({String.t, t}) :: {String.t, t}
    def hash_token({raw_token, struct_token}) do
      {raw_token, %{struct_token | token: :crypto.hash(@hash_algorithm, struct_token.token)}}
    end
  end

  @spec user_module_to_token_module(module) :: module
  defp user_module_to_token_module(module) do
    module.__schema__(:association, @token_association).related
  end

  @spec user_from_token_query(module :: module, token :: String.t, context :: String.t, duration :: pos_integer) :: Ecto.Query.t
  defp user_from_token_query(module, token, context, duration) do
    from t in user_module_to_token_module(module.schema()),
      join: u in assoc(t, :user),
      where: t.token == ^token and t.context == ^context and t.inserted_at > ago(^duration, "second"), # and (not) is_nil(u.confirmed_at)
      select: u
  end

  @spec user_from_token_with_mail_query(module :: module, token :: String.t, context :: String.t, duration :: pos_integer) :: Ecto.Query.t
  defp user_from_token_with_mail_query(module, token, context, duration) do
    from([t, u] in user_from_token_query(module, token, context, duration), where: t.sent_to == u.email)
  end

  @doc ~S"""
  TODO (doc)
  """
  @spec user_from_token_with_mail_match(module :: module, token :: String.t, context :: String.t, duration :: pos_integer) :: Haytni.nilable(Haytni.user)
  def user_from_token_with_mail_match(module, token, context, duration) do
    user_from_token_with_mail_query(module, token, context, duration)
    |> module.repo().one()
  end

  @doc ~S"""
  TODO (doc)
  """
  @spec user_from_token_without_mail_match(module :: module, user :: Haytni.user, token :: String.t, context :: String.t, duration :: pos_integer) :: Haytni.nilable(Haytni.user)
  def user_from_token_without_mail_match(module, user, token, context, duration) do
    #from([t, u] in user_from_token_query(module, token, context, duration), where: t.sent_to != u.email)
    from(
      u in user.__struct__, # <=> module.schema(),
      join: t in assoc(u, ^@token_association),
      where: t.sent_to != u.email and t.token == ^token and t.context == ^context and t.inserted_at > ago(^duration, "second"),
      select: t
    )
    |> module.repo().one()
  end

  @doc ~S"""
  Helper (intended to be composed) to build the query to select all tokens associated to a given user and for the specified contexts
  """
  @spec tokens_from_user_query(user :: Haytni.user, contexts :: String.t | nonempty_list(String.t) | :all) :: Ecto.Query.t
  def tokens_from_user_query(user, :all) do
    from Ecto.assoc(user, @token_association), where: [user_id: ^user.id]
  end

  def tokens_from_user_query(user, contexts = [_ | _]) do
    from t in Ecto.assoc(user, @token_association), where: t.user_id == ^user.id and t.context in ^contexts
  end

  def tokens_from_user_query(user, context)
    when is_binary(context)
  do
    tokens_from_user_query(user, [context])
  end

  @doc ~S"""
  TODO (doc/experimental)
  """
  @spec purge_expired_tokens(module :: module) :: String.t
  def purge_expired_tokens(module) do
    conditions =
      module.plugins_with_config()
      |> Enum.reduce(
        false,
        fn {plugin, config}, conditions_as_acc ->
          if function_exported?(plugin, :expired_tokens_query, 1) do
            dynamic([t], ^conditions_as_acc or ^plugin.expired_tokens_query(config))
          else
            conditions_as_acc
          end
        end
      )
    q = from t in user_module_to_token_module(module.schema()), where: ^conditions
    #{query, _params} =
    Ecto.Adapters.SQL.to_sql(:all, module.repo(), q)
  end

  @doc ~S"""
  Deletes all tokens associated to the given *user* and contexts (if not `:all`)
  """
  @spec delete_tokens_in_multi(multi :: Ecto.Multi.t, name :: Ecto.Multi.name, user :: Haytni.user, contexts :: String.t | nonempty_list(String.t) | :all) :: Ecto.Multi.t
  def delete_tokens_in_multi(multi = %Ecto.Multi{}, name, user = %_{}, contexts) do
    Ecto.Multi.delete_all(multi, name, tokens_from_user_query(user, contexts))
  end

  @doc ~S"""
  When the *multi* will be executed, generates and inserts a token, associated to the user resulting of a previous operation of *multi* identified by the name *user_name*.

  Exemple:

      Ecto.Multi.new()
      |> Ecto.Multi.update(:user, Ecto.Changeset.change(user, changes))
      |> Haytni.Token.insert_token_in_multi(:token, :user, "context")
      |> Repo.Transaction()
  """
  @spec insert_token_in_multi(multi :: Ecto.Multi.t, token_name :: Ecto.Multi.name, user_name :: Ecto.Multi.name, context :: String.t) :: Ecto.Multi.t
  def insert_token_in_multi(multi = %Ecto.Multi{}, token_name, user_name, context) do
    Ecto.Multi.insert(
      multi,
      token_name,
      fn %{^user_name => user} ->
        build_and_assoc_token(user, user.email, context)
      end
    )
  end

  @doc ~S"""
  Generates a token associated to *user* and add it to the multi for later insertion.
  """
  @spec insert_token_in_multi(multi :: Ecto.Multi.t, name :: Ecto.Multi.name, user :: Haytni.user, email :: String.t, context :: String.t) :: Ecto.Multi.t
  def insert_token_in_multi(multi = %Ecto.Multi{}, name, user = %_{}, email, context) do
    Ecto.Multi.insert(multi, name, build_and_assoc_token(user, email, context))
  end

  @doc ~S"""
  Fetch the user associated to the given *token*, and if it is still valid. Returns `nil` if none.
  """
  @spec verify(module :: module, token :: String.t, duration :: pos_integer, context :: String.t) :: Haytni.nilable(Haytni.user)
  def verify(module, token, duration, context) do
    from(
      t in user_module_to_token_module(module.schema()),
      join: user in assoc(t, :user), # :user <=> module.scope()
      where: t.token == ^token and t.inserted_at > ago(^duration, "second") and t.context == ^context,
      select: user
    )
    |> module.repo().one()
  end

  if false do
    @doc ~S"""
    TODO (doc or removal)
    """
    @spec revoke_user_tokens(module :: module, user :: Haytni.user) :: {integer, nil}
    def revoke_user_tokens(module, user = %_{}) do
      user
      |> Ecto.assoc(@token_association)
      |> module.repo().delete_all()
    end
  end
end
