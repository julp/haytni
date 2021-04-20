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
  Generates a token, associated to a given user and a given email address (*sent_to*).

  NOTE: this is a "low level" function for specific needs, the token is **NOT** persisted (designed to be inserted later
  by an Ecto.Multi). Use the higher level function `insert_token_in_multi/4` if it feet your needs.
  """
  @spec build_and_assoc_token(user :: Haytni.user, sent_to :: String.t, context :: String.t | atom) :: t
  def build_and_assoc_token(user = %_{}, sent_to, context) do
    Ecto.build_assoc(user, @token_association, token: new(@token_length), context: context, sent_to: sent_to)
  end

  @spec url_decode(token :: t) :: String.t
  def token(token = %_{}) do
    token.token
  end

  @base64_options [padding: false]
  @doc ~S"""
  Encodes a token to safely figure in an URL
  """
  @spec url_encode(token :: t) :: String.t
  def url_encode(token = %_{}) do
    Base.url_encode64(token.token, @base64_options)
  end

  @doc ~S"""
  Decodes a token previously encoded by `url_encode/1`
  """
  @spec url_decode(token :: String.t) :: {:ok, String.t} | :error
  def url_decode(token) do
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
  Returns the user associated to the given non-expired token, `nil` if none matches. This function checks that the current email address
  of the found user is the same than the the one associated to the token at its creation.
  """
  @spec user_from_token_with_mail_match(module :: module, token :: String.t, context :: String.t, duration :: pos_integer) :: Haytni.nilable(Haytni.user)
  def user_from_token_with_mail_match(module, token, context, duration) do
    module
    |> user_from_token_with_mail_query(token, context, duration)
    |> module.repo().one()
  end

  @doc ~S"""
  Returns the user associated to the given non-expired token, `nil` if none matches but, in opposition to `user_from_token_with_mail_match/4`, the email
  address between the user and the token is expected (has) to be different. This behaviour (and function) is primarily intended to change its email address.
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
  Helper to build the query (intended to be composed) to select all tokens associated to a given user and for the specified contexts
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
  Purges all expired tokens.

  Returns the number of deleted tokens.
  """
  @spec purge_expired_tokens(module :: module) :: non_neg_integer
  def purge_expired_tokens(module) do
    {count, nil} =
      module.plugins_with_config()
      |> Enum.reduce(
        from(t in user_module_to_token_module(module.schema())),
        fn {plugin, config}, query_as_acc ->
          if function_exported?(plugin, :expired_tokens_query, 2) do
            plugin.expired_tokens_query(query_as_acc, config)
          else
            query_as_acc
          end
        end
      )
      |> module.repo().delete_all()
    count
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
  Deletes all tokens associated to a given user.

  Returns the number of tokens that were actually deleted (expired tokens included).
  """
  @spec revoke_user_tokens(module :: module, user :: Haytni.user) :: non_neg_integer
  def revoke_user_tokens(module, user = %_{}) do
    {count, nil} =
      user
      |> Ecto.assoc(@token_association)
      |> module.repo().delete_all()
    count
  end
end
