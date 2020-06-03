defmodule Haytni.LockablePlugin do
  @default_unlock_path "/unlock"
  @unlock_path_key :unlock_path

  @moduledoc """
  This plugin locks an account after a specified number of failed sign-in attempts. User can unlock its account via email
  and/or after a specified time period.

  Fields:

    * failed_attempts (integer, default: `0`): the current count of successive failures to login
    * locked_at (datetime@utc, nullable, default: `NULL`): when the account was locked (`NULL` while the account is not locked)
    * unlock_token (string, nullable, unique, default: `NULL`): the token send to the user to unlock its account

  Configuration:

    * `maximum_attempts` (default: `20`): the amount of successive attempts to login before locking the corresponding account
    * `unlock_token_length` (default: `32`): the length of the generated token
    * `unlock_keys` (default: `~W[email]a`): the field(s) to match to accept the unlock request
    * `unlock_in` (default: `{1, :hour}`): delay to automatically unlock the account
    * `unlock_strategy` (default: `:both`): strategy used to unlock an account. One of:

      + `:email`: sends an unlock link to the user email
      + `:time`: re-enables login after a certain amount of time (see :unlock_in below)
      + `:both`: enables both strategies
      + `:none`: no unlock strategy. You should handle unlocking by yourself.

            stack Haytni.LockablePlugin,
              maximum_attempts: 20,
              unlock_in: {1, :hour},
              unlock_strategy: :both,
              unlock_keys: ~W[email]a,
              unlock_token_length: 32

  Routes:

    * `haytni_<scope>_unlock_path` (actions: new/create, show): default path is `#{inspect(@default_unlock_path)}` but you can override it by the
      `#{inspect(@unlock_path_key)}` option when calling YourApp.Haytni.routes/1 from your router (eg: `YourApp.Haytni.routes(unlock_path: "/unblock")`)
  """

  import Haytni.Gettext

  defmodule Config do
    defstruct maximum_attempts: 20, unlock_in: {1, :hour}, unlock_strategy: :both, unlock_keys: ~W[email]a, unlock_token_length: 32

    @type unlock_strategy :: :both | :email | :time | :none

    @type t :: %__MODULE__{
      maximum_attempts: pos_integer,
      unlock_in: Haytni.duration,
      unlock_strategy: unlock_strategy,
      unlock_keys: [atom],
      unlock_token_length: pos_integer,
    }

    @doc ~S"""
    Returns all available strategies (all possible values for *unlock_strategy* parameter)
    """
    @spec available_strategies() :: [unlock_strategy]
    def available_strategies do
      ~W[both email none time]a
    end

    @doc ~S"""
    Returns strategies involving sending emails
    """
    @spec email_strategies() :: [unlock_strategy]
    def email_strategies do
      ~W[both email]a
    end
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %Haytni.LockablePlugin.Config{}
    |> Haytni.Helpers.merge_config(options, ~W[unlock_in]a)
  end

  @impl Haytni.Plugin
  def files_to_install do
    import Mix.Tasks.Haytni.Install, only: [web_path: 0, timestamp: 0]
    [
      # HTML
      {:eex, "views/unlock_view.ex", Path.join([web_path(), "views", "haytni", "unlock_view.ex"])},
      {:eex, "templates/unlock/new.html.eex", Path.join([web_path(), "templates", "haytni", "unlock", "new.html.eex"])},
      # email
      {:eex, "views/email/lockable_view.ex", Path.join([web_path(), "views", "haytni", "email", "lockable_view.ex"])},
      {:eex, "templates/email/lockable/unlock_instructions.text.eex", Path.join([web_path(), "templates", "haytni", "email", "lockable", "unlock_instructions.text.eex"])},
      {:eex, "templates/email/lockable/unlock_instructions.html.eex", Path.join([web_path(), "templates", "haytni", "email", "lockable", "unlock_instructions.html.eex"])},
      # migration
      {:eex, "migrations/0-lockable_changes.ex", Path.join([web_path(), "..", "..", "priv", "repo", "migrations", "#{timestamp()}_haytni_lockable_changes.ex"])}, # TODO: less "hacky"
    ]
  end

  @impl Haytni.Plugin
  def fields(_module) do
    quote do
      field :failed_attempts, :integer, default: 0
      field :locked_at, :utc_datetime, default: nil # NULLABLE
      field :unlock_token, :string, default: nil # NULLABLE, UNIQUE
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
  def invalid?(user = %_{}, config) do
    if locked?(user, config) do
      {:error, dgettext("haytni", "account is locked due to an excessive number of unsuccessful sign in attempts, please check your emails.")}
    else
      false
    end
  end

  @doc ~S"""
  The (database) attributes as a keyword-list to turn a user as a locked account
  """
  @spec lock_attributes(config :: Config.t) :: Keyword.t
  def lock_attributes(config) do
    [
      locked_at: Haytni.Helpers.now(),
      unlock_token: Haytni.Token.generate(config.unlock_token_length),
    ]
  end

  @impl Haytni.Plugin
  def on_failed_authentication(user = %_{}, multi, keywords, module, config) do
    if user.failed_attempts + 1 >= config.maximum_attempts && !locked?(user, config) do
      multi = if email_strategy_enabled?(config) do
        Ecto.Multi.run(
          multi,
          :send_unlock_instructions,
          fn _repo, %{user: user} ->
            send_unlock_instructions_mail_to_user(user, module, config)
            {:ok, :success}
          end
        )
      else
        multi
      end
      {multi, Keyword.merge(keywords, lock_attributes(config))}
    else
      # TODO: this is not really safe, better to append to the multi an UPDATE ... SET failed_attempts = failed_attempts + 1 ...
      {multi, Keyword.put(keywords, :failed_attempts, user.failed_attempts + 1)}
    end
  end

  @impl Haytni.Plugin
  def on_successful_authentication(conn = %Plug.Conn{}, _user = %_{}, multi = %Ecto.Multi{}, keywords, _config) do
    # reset failed_attempts
    {conn, multi, Keyword.put(keywords, :failed_attempts, 0)}
  end

  @doc ~S"""
  Returns `true` if *user* account is currently locked.
  """
  @spec locked?(user :: Haytni.user, config :: Config.t) :: boolean
  def locked?(user = %_{}, config) do
    user.locked_at != nil && !lock_expired?(user, config)
  end

  @spec lock_expired?(user :: Haytni.user, config :: Config.t) :: boolean
  defp lock_expired?(user, config) do
    config.unlock_strategy in ~W[both time]a && DateTime.diff(DateTime.utc_now(), user.locked_at) >= config.unlock_in
  end

  @spec send_unlock_instructions_mail_to_user(user :: Haytni.user, module :: module, config :: Config.t) :: {:ok, Haytni.user}
  defp send_unlock_instructions_mail_to_user(user, module, config) do
    if email_strategy_enabled?(config) do
      Haytni.LockableEmail.unlock_instructions_email(user, module, config)
      |> module.mailer().deliver_later()
    end
    {:ok, user}
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
  The (database) attributes as a keyword-list to turn an account to unlocked state
  """
  @spec unlock_attributes() :: Keyword.t
  def unlock_attributes do
    [unlock_token: nil, failed_attempts: 0, locked_at: nil]
  end

  @doc ~S"""
  Unlock an account from an unlock token.

  Returns the user as `{:ok, user}` if the token exists and `{:error, message}` if not.
  """
  @spec unlock(module :: module, config :: Config.t, token :: String.t) :: {:ok, Haytni.user} | {:error, String.t}
  def unlock(module, config, token) do
    if email_strategy_enabled?(config) do
      case Haytni.get_user_by(module, unlock_token: token) do
        nil ->
          {:error, invalid_token_message()}
        user = %_{} ->
          Haytni.update_user_with(module, user, unlock_attributes())
      end
    else
      {:error, email_strategy_disabled_message()}
    end
  end

  @doc ~S"""
  Converts the "raw" parameters received by the controller to request a new token to unlock its account to an `%Ecto.Changeset{}`
  """
  @spec unlock_request_changeset(config :: Config.t, request_params :: %{String.t => String.t}) :: Ecto.Changeset.t
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

    * `{:error, :email_strategy_disabled}` if `:email` strategy is disabled
    * `{:error, changeset}` if there is no such account matching `config.unlock_keys` or if the account is not currently locked (`changeset.errors` is set consequently)
    * `{:ok, user}` if successful

  In strict mode (`config :haytni, mode: :strict`), returned values are different:

    * `{:error, :email_strategy_disabled}` if `:email` strategy is disabled
    * `{:error, changeset}` if (form) fields are empty
    * `{:ok, nil}` if no one matches `config.unlock_keys` or if the account is not currently locked
    * `{:ok, user}` if successful (meaning an email has been sent)
  """
  @spec resend_unlock_instructions(module :: module, config :: Config.t, request_params :: %{optional(String.t) => String.t}) :: {:ok, nil | Haytni.user} | {:error, Ecto.Changeset.t}
  def resend_unlock_instructions(module, config, request_params = %{}) do
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
            %_{unlock_token: nil} ->
              if Application.get_env(:haytni, :mode) == :strict do
                {:ok, nil}
              else
                #Haytni.Helpers.apply_base_error(changeset, not_locked_message())
                Haytni.Helpers.mark_changeset_keys_with_error(changeset, config.unlock_keys, not_locked_message())
              end
            user = %_{} ->
              user
              |> send_unlock_instructions_mail_to_user(module, config)
          end
        else
          {:error, :email_strategy_disabled}
        end
      error = {:error, %Ecto.Changeset{}} ->
        error
    end
  end
end
