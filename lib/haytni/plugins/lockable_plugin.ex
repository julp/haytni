defmodule Haytni.LockablePlugin do
  @default_unlock_path "/unlock"
  @unlock_path_key :unlock_path

  @default_unlock_in {1, :hour}
  @default_unlock_within {3, :day}
  @default_unlock_strategy :both
  @default_maximum_attempts 20
  @default_unlock_keys ~W[email]a

  @moduledoc """
  This plugin locks an account after a specified number of failed sign-in attempts. User can unlock its account via email
  and/or after a specified time period.

  Fields:

    * failed_attempts (integer, default: `0`): the current count of successive failures to login
    * locked_at (datetime@utc, nullable, default: `NULL`): when the account was locked (`NULL` while the account is not locked)

  Configuration:

    * `maximum_attempts` (default: `#{inspect @default_maximum_attempts}`): the amount of successive attempts to login before locking the corresponding account
    * `unlock_keys` (default: `#{inspect @default_unlock_keys}`): the field(s) to match to accept the unlock request
    * `unlock_in` (default: `#{inspect @default_unlock_in}`): delay to automatically unlock the account
    * `unlock_within` (default: `#{inspect @default_unlock_within}`): delay after which unlock token is considered as expired (ie the user has to request a new one)
    * `unlock_strategy` (default: `#{inspect @default_unlock_strategy}`): strategy used to unlock an account. One of:

      + `:email`: sends an unlock link to the user email
      + `:time`: re-enables login after a certain amount of time (see :unlock_in below)
      + `:both`: enables both strategies
      + `:none`: no unlock strategy. You should handle unlocking by yourself.

            stack Haytni.LockablePlugin,
              maximum_attempts: #{inspect @default_maximum_attempts},
              unlock_in: #{inspect @default_unlock_in},
              unlock_within: #{inspect @default_unlock_within},
              unlock_strategy: #{inspect @default_unlock_strategy},
              unlock_keys: #{inspect @default_unlock_keys}

  Routes:

    * `haytni_<scope>_unlock_path` (actions: new/create, show): default path is `#{inspect(@default_unlock_path)}` but you can override it by the
      `#{inspect(@unlock_path_key)}` option when calling YourApp.Haytni.routes/1 from your router (eg: `YourApp.Haytni.routes(#{@unlock_path_key}: "/unblock")`)
  """

  import Haytni.Gettext

  defmodule Config do
    defstruct maximum_attempts: 20,
      unlock_in: {1, :hour},
      unlock_within: {3, :day},
      unlock_strategy: :both,
      unlock_keys: ~W[email]a

    @type unlock_strategy :: :both | :email | :time | :none

    @type t :: %__MODULE__{
      maximum_attempts: pos_integer,
      unlock_in: Haytni.duration,
      unlock_within: Haytni.duration,
      unlock_strategy: unlock_strategy,
      unlock_keys: [atom, ...],
    }

    @doc ~S"""
    Returns all available strategies (all possible values for *unlock_strategy* parameter)
    """
    @spec available_strategies() :: [unlock_strategy, ...]
    def available_strategies do
      ~W[both email none time]a
    end

    @doc ~S"""
    Returns strategies involving sending emails
    """
    @spec email_strategies() :: [unlock_strategy, ...]
    def email_strategies do
      ~W[both email]a
    end
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %Haytni.LockablePlugin.Config{}
    |> Haytni.Helpers.merge_config(options, ~W[unlock_in unlock_within]a)
  end

  @impl Haytni.Plugin
  def files_to_install(_base_path, web_path, scope, timestamp) do
    [
      # HTML
      {:eex, "views/unlock_view.ex", Path.join([web_path, "views", "haytni", scope, "unlock_view.ex"])},
      {:eex, "templates/unlock/new.html.eex", Path.join([web_path, "templates", "haytni", scope, "unlock", "new.html.eex"])},
      # email
      {:eex, "views/email/lockable_view.ex", Path.join([web_path, "views", "haytni", scope, "email", "lockable_view.ex"])},
      {:eex, "templates/email/lockable/unlock_instructions.text.eex", Path.join([web_path, "templates", "haytni", scope, "email", "lockable", "unlock_instructions.text.eex"])},
      {:eex, "templates/email/lockable/unlock_instructions.html.eex", Path.join([web_path, "templates", "haytni", scope, "email", "lockable", "unlock_instructions.html.eex"])},
      # migration
      {:eex, "migrations/0-lockable_changes.exs", Path.join([web_path, "..", "..", "priv", "repo", "migrations", "#{timestamp}_haytni_lockable_#{scope}_changes.exs"])},
    ]
  end

  @impl Haytni.Plugin
  def fields(_module) do
    quote do
      field :failed_attempts, :integer, default: 0
      field :locked_at, :utc_datetime, default: nil # NULLABLE
    end
  end

  @impl Haytni.Plugin
  def routes(prefix_name, options) do
    prefix_name = :"#{prefix_name}_unlock"
    unlock_path = Keyword.get(options, @unlock_path_key, @default_unlock_path)
    quote bind_quoted: [prefix_name: prefix_name, unlock_path: unlock_path] do
      resources unlock_path, HaytniWeb.Lockable.UnlockController, singleton: true, only: ~W[new create show]a, as: prefix_name
    end
  end

  @impl Haytni.Plugin
  def invalid?(user = %_{}, _module, config) do
    if locked?(user, config) do
      {:error, dgettext("haytni", "account is locked due to an excessive number of unsuccessful sign in attempts, please check your emails.")}
    else
      false
    end
  end

  @doc ~S"""
  The (database) attributes as a keyword-list to turn a user as a locked account
  """
  @spec lock_attributes() :: Keyword.t
  def lock_attributes do
    [
      locked_at: Haytni.Helpers.now(),
    ]
  end

  @doc ~S"""
  The (database) attributes as a keyword-list to turn an account to unlocked state
  """
  @spec unlock_attributes() :: Keyword.t
  def unlock_attributes do
    [
      failed_attempts: 0,
      locked_at: nil,
    ]
  end

  @impl Haytni.Plugin
  def on_failed_authentication(user = %_{}, multi, keywords, module, config) do
    if user.failed_attempts + 1 >= config.maximum_attempts and not locked?(user, config) do
      # the amount of maximum attempts is reached, lock the account
      multi = if email_strategy_enabled?(config) do
        multi
        |> Haytni.Token.insert_token_in_multi(:token, user, user.email, token_context())
        |> send_instructions_in_multi(:user, :token, module, config)
      else
        multi
      end
      {multi, Keyword.merge(keywords, lock_attributes())}
    else
      # the account is not locked for now, just increment failed_attempts
      import Ecto.Query

      schema = user.__struct__ # <=> module.schema()
      where = dynamic([u], is_nil(u.locked_at))
      where = if config.unlock_strategy in ~W[both time]a do
        dynamic([u], u.locked_at < ago(^config.unlock_in, "second") or ^where)
      else
        where
      end
      where =
        schema.__schema__(:primary_key)
        |> Enum.reduce(
          where,
          fn field, acc ->
            dynamic([u], field(u, ^field) == ^Map.fetch!(user, field) and ^acc)
          end
        )
      query = from(
        u in schema,
        #select: u.failed_attempts, # not supported by MySQL
        where: ^where
      )

      multi =
        multi
        |> Ecto.Multi.update_all(:increment_failed_attempts, query, inc: [failed_attempts: 1])
      # NOTE: uncomment the following line, remove quotes and assignment below if *select* key from the query above is left uncommented
      #maximum_attempts = config.maximum_attempts
      _ = """
        |> Ecto.Multi.run(
          :lock,
          fn
            # increment done and database returned the new amount of failed attempts
            repo, %{increment_failed_attempts: {1, [new_failed_attempts]}} when is_integer(new_failed_attempts) and new_failed_attempts >= maximum_attempts ->
              multi =
                Ecto.Multi.new()
                |> Haytni.update_user_in_multi_with(:user, user, lock_attributes())
              multi = if email_strategy_enabled?(config) do
                multi
                |> Haytni.Token.insert_token_in_multi(:token, user, user.email, token_context())
                |> send_instructions_in_multi(:user, :token, module, config)
              else
                multi
              end
              |> repo.transaction() # return the multi if we can't do a transaction into an other one?
              # {:ok, true}
            # the account is already locked and has not yet expired or the database doesn't have any equivalent to PostgreSQL's RETURNING clause
            _repo, _ ->
              {:ok, false}
          end
        )
      """

      {multi, keywords}
    end
  end

  @impl Haytni.Plugin
  def on_successful_authentication(conn = %Plug.Conn{}, user = %_{}, multi = %Ecto.Multi{}, keywords, _module, _config) do
    # reset failed_attempts and revoke tokens intended for unlocking the current account
    {conn, Haytni.Token.delete_tokens_in_multi(multi, :tokens, user, token_context()), Keyword.put(keywords, :failed_attempts, 0)}
  end

  @doc ~S"""
  Returns `true` if *user* account is currently locked.
  """
  @spec locked?(user :: Haytni.user, config :: Config.t) :: boolean
  def locked?(user = %_{}, config) do
    user.locked_at != nil and not lock_expired?(user, config)
  end

  @spec lock_expired?(user :: Haytni.user, config :: Config.t) :: boolean
  defp lock_expired?(user, config) do
    config.unlock_strategy in ~W[both time]a and DateTime.diff(DateTime.utc_now(), user.locked_at) >= config.unlock_in
  end

  @spec send_unlock_instructions_mail_to_user(user :: Haytni.user, token :: String.t, module :: module, config :: Config.t) :: Bamboo.Email.t
  defp send_unlock_instructions_mail_to_user(user, token, module, config) do
    user
    |> Haytni.LockableEmail.unlock_instructions_email(token, module, config)
    |> module.mailer().deliver_later()
  end

  @spec send_instructions_in_multi(multi :: Ecto.Multi.t, user_name :: Ecto.Multi.name, token_name :: Ecto.Multi.name, module :: module, config :: Config.t) :: Ecto.Multi.t
  # multi = %Ecto.Multi{}
  defp send_instructions_in_multi(multi, user_name, token_name, module, config) do
    #Ecto.Multi.run(
    multi.__struct__.run(
      multi,
      :send_unlock_instructions,
      fn _repo, %{^user_name => user, ^token_name => token} ->
        send_unlock_instructions_mail_to_user(user, Haytni.Token.encode_token(token), module, config)
        {:ok, true}
      end
    )
  end

  @doc ~S"""
  Returns `true` if it's the last attempt before account locking in case of a new sign-in failure
  """
  @spec last_attempt?(user :: Haytni.user, config :: Config.t) :: boolean
  def last_attempt?(user = %_{}, config = %Haytni.LockablePlugin.Config{}) do
    user.failed_attempts == config.maximum_attempts - 1
  end

  @doc ~S"""
  Returns `true` if `:email` strategy (included in `:both`) is enabled
  """
  @spec email_strategy_enabled?(config :: Config.t) :: boolean
  def email_strategy_enabled?(config) do
    config.unlock_strategy in Config.email_strategies()
  end

  use Haytni.Tokenable

  #@spec token_context() :: String.t
  @impl Haytni.Tokenable
  def token_context do
    "lockable"
  end

  @impl Haytni.Tokenable
  def expired_tokens_query(config) do
    # mais l'appelant devrait pouvoir appeler la callback token_context/0 de lui-même
    # en fait la seule partie qui change (que l'on devrait renvoyer ?) c'est config.unlock_within
    "context == #{token_context()} AND inserted_at > ago(#{config.unlock_within}, \"second\")"

    import Ecto.Query

    dynamic([t], t.context == ^token_context() and t.inserted_at > ago(^config.unlock_within, "second"))
  end

  @doc ~S"""
  The translated string to display when email strategy is switched off for someone who
  would want to request an unlock token or have previously received one by email.
  """
  @spec email_strategy_disabled_message() :: String.t
  def email_strategy_disabled_message do
    dgettext("haytni", "Unlocking accounts through email is currently disabled.")
  end

  @doc ~S"""
  The translated string to display when an unlock token is invalid (ie not associated to someone)
  """
  @spec invalid_token_message() :: String.t
  def invalid_token_message do
    dgettext("haytni", "The given unlock token is invalid.")
  end

  @doc ~S"""
  Unlock an account from a URL base64 encoded unlock token.

  Returns:
    * `{:error, :strategy, message, %{}}` if email strategy is currently disabled
    * conforms to Ecto.Multi for any other error
    * `{:ok, %{user: nil}}`  if the token doesn't exist or is expired
    * `{:ok, %{user: user}}` if the token exists and is valid
  """
  @spec unlock(module :: module, config :: Config.t, token :: String.t) :: Haytni.multi_result
  def unlock(module, config, token) do
if true do
    Ecto.Multi2.new()
    |> Ecto.Multi2.run(:strategy, fn _repo, _changes ->
        if email_strategy_enabled?(config) do
          {:ok, true}
        else
          {:error, email_strategy_disabled_message()}
        end
      end
    )
    |> Ecto.Multi2.one(:user_from_token, fn _changes ->
        case Haytni.Token.decode_token(token) do
          {:ok, unlock_token} ->
            Haytni.Token.user_from_token_with_mail_query(module, unlock_token, token_context(), config.unlock_within)
          _ ->
            nil
        end
      end
    )
    |> Haytni.Multi.update_user_with2(:user, :user_from_token, unlock_attributes())
    |> Haytni.Multi.delete_tokens(:tokens, :user, token_context())
    |> Ecto.Multi2.transaction(module.repo())
    #multi = Ecto.Multi.new()
    #if email_strategy_enabled?(config) do
      #multi
      #|> Haytni.Multi.select(:user, Haytni.Token.user_from_token_with_mail_query(module, token, token_context(), config.unlock_within), invalid_token_message())
      #|> Ecto.Multi.update(:updated_user, fn %{user: user} ->
          #Ecto.Changeset.change(user, unlock_attributes())
        #end
      #)
      #|> Ecto.Multi.delete_all(:tokens, fn %{user: user} ->
          #Haytni.Token.tokens_from_user_query(user, token_context())
        #end
      #)
    #else
      ##Haytni.Multi.apply_base_error(multi, :strategy, changeset, email_strategy_disabled_message())
      #Ecto.Multi.error(multi, :strategy, email_strategy_disabled_message())
    #end
    #|> module.repo().transaction()
else
    if email_strategy_enabled?(config) do
      with(
        {:ok, unlock_token} <- Haytni.Token.decode_token(token),
        user = %_{} <- Haytni.Token.user_from_token_with_mail_match(module, unlock_token, token_context(), config.unlock_within)
      ) do
        {:ok, %{user: user}} =
          Ecto.Multi.new()
          |> Haytni.update_user_in_multi_with(:user, user, unlock_attributes())
          |> Haytni.Token.delete_tokens_in_multi(:tokens, user, token_context())
          |> module.repo().transaction()
        {:ok, user}
      else
        _ ->
          {:error, invalid_token_message()}
      end
    else
      {:error, email_strategy_disabled_message()}
    end
end
  end

  @doc ~S"""
  Converts the "raw" parameters received by the controller to request a new token to unlock its account to an `%Ecto.Changeset{}`
  """
  @spec unlock_request_changeset(config :: Config.t, request_params :: Haytni.params) :: Ecto.Changeset.t
  def unlock_request_changeset(config, request_params \\ %{}) do
    Haytni.Helpers.to_changeset(request_params, [:referer | config.unlock_keys], config.unlock_keys)
  end

  @doc ~S"""
  The translated string to display when a user request a token while he is not currently locked
  """
  @spec not_locked_message() :: String.t
  def not_locked_message do
    dgettext("haytni", "This account is not currently locked")
  end

  @doc ~S"""
  Resend, by email, the instructions to unlock an account.

  Returns:

    * ~~`{:error, :email_strategy_disabled}` if `:email` strategy is disabled~~
    * ~~`{:error, changeset}` if there is no such account matching `config.unlock_keys` or if the account is not currently locked (`changeset.errors` is set consequently)~~
    * ~~`{:ok, user}` if successful~~

  In strict mode (`config :haytni, mode: :strict`), returned values are different:

    * ~~`{:error, :email_strategy_disabled}` if `:email` strategy is disabled~~
    * ~~`{:error, changeset}` if (form) fields are empty~~
    * ~~`{:ok, nil}` if no one matches `config.unlock_keys` or if the account is not currently locked~~
    * ~~`{:ok, user}` if successful (meaning an email has been sent)~~
  """
  @spec resend_unlock_instructions(module :: module, config :: Config.t, request_params :: Haytni.params) :: Haytni.multi_result
  def resend_unlock_instructions(module, config, request_params = %{}) do
if true do
    #multi = Ecto.Multi.new()
    changeset = unlock_request_changeset(config, request_params)

    Ecto.Multi2.new()
    |> Ecto.Multi2.run(:strategy, fn _repo, _changes ->
        if email_strategy_enabled?(config) do
          {:ok, true}
        else
          Haytni.Helpers.apply_base_error(changeset, email_strategy_disabled_message())
        end
      end
    )
    |> Ecto.Multi2.apply_action(:params, changeset)
    |> Ecto.Multi2.one(:user, fn %{params: sanitized_params} ->
        import Ecto.Query

        from(
          u in module.schema(),
          where: not is_nil(u.locked_at),
          where: ^Map.to_list(Map.delete(sanitized_params, :referer))
        )
      end
    )
    |> Haytni.Multi.insert_token(:token, :user, token_context())
    |> send_instructions_in_multi(:user, :token, module, config)
    |> Ecto.Multi2.transaction(module.repo())
    #if email_strategy_enabled?(config) do
      #import Ecto.Query

      #multi
      #|> Haytni.Multi.apply_changeset(:params, changeset)
      #|> Haytni.Multi.get_user(:user, module, :params, dynamic([u], not is_nil(u.locked_at)))
      ## TODO : comment gérer l'absence de correspondance en :user ?
      ## - {:ok, nil} que les prochaines opérations doivent ignorer ?
      ## - {:error, changeset} mais comment créer le changeset et avec quelles erreurs ? (:base vs config.unlock_keys)
      #|> Haytni.Multi.insert_token(:token, :user, token_context())
      #|> send_instructions_in_multi(:user, :token, module, config)
    #else
      #Haytni.Multi.apply_base_error(multi, :strategy, changeset, email_strategy_disabled_message())
    #end
    #|> module.repo().transaction()
else
    changeset = unlock_request_changeset(config, request_params)

    changeset
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, sanitized_params} ->
        if email_strategy_enabled?(config) do
          sanitized_params = Map.delete(sanitized_params, :referer)
          case Haytni.get_user_by(module, sanitized_params) do
            nil ->
              if Application.get_env(:haytni, :mode) == :strict do
                {:ok, nil}
              else
                Haytni.Helpers.mark_changeset_keys_as_unmatched(changeset, config.unlock_keys)
              end
            %_{locked_at: nil} ->
              if Application.get_env(:haytni, :mode) == :strict do
                {:ok, nil}
              else
                #Haytni.Helpers.apply_base_error(changeset, not_locked_message())
                Haytni.Helpers.mark_changeset_keys_with_error(changeset, config.unlock_keys, not_locked_message())
              end
            user = %_{} ->
              {:ok, %{user: user}} =
                Ecto.Multi.new()
                # TODO: passer Haytni.get_user_by(module, sanitized_params) en Multi à la place du Ecto.Multi.run ci-dessous ?
                |> Haytni.Multi.assign(:user, user)
                |> Haytni.Token.insert_token_in_multi(:token, user, user.email, token_context())
                |> send_instructions_in_multi(:user, :token, module, config)
                |> module.repo().transaction()
              {:ok, user}
          end
        else
          {:error, :email_strategy_disabled}
        end
      error = {:error, %Ecto.Changeset{}} ->
        error
    end
  end
end # if true/false do
end
