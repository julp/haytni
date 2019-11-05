defmodule Haytni.LockablePlugin do
  @moduledoc ~S"""
  This plugin locks an account after a specified number of failed sign-in attempts. User can unlock its account via email
  or after a specified time period.

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

  Routes:

    * `unlock_path` (actions: new/create, show)
  """

  @typep unlock_strategy :: :both | :email | :time | :none

  #import Plug.Conn
  import Haytni.Gettext

  use Haytni.Plugin
  use Haytni.Config, [
    maximum_attempts: 20,
    unlock_in: {1, :hour},
    unlock_strategy: :both,
    unlock_keys: ~W[email]a,
    unlock_token_length: 32
  ]

if false do
  # TODO: for use in tests instead to be repeated and hardcoded
  def available_strategies do
    ~W[both email none time]a
  end

  def email_strategies do
    ~W[both email]a
  end
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
      {:eex, "migrations/lockable_changes.ex", Path.join([web_path(), "..", "..", "priv", "repo", "migrations", "#{timestamp()}_haytni_lockable_changes.ex"])} # TODO: less "hacky"
    ]
  end

  @impl Haytni.Plugin
  def fields do
    quote do
      field :failed_attempts, :integer, default: 0
      field :locked_at, :utc_datetime, default: nil # NULLABLE
      field :unlock_token, :string, default: nil # NULLABLE, UNIQUE
    end
  end

  @impl Haytni.Plugin
  def routes(_scope, _options) do
    quote do
      resources "/unlock", HaytniWeb.Lockable.UnlockController, as: :unlock, singleton: true, only: ~W[new create show]a
    end
  end

  @impl Haytni.Plugin
  def invalid?(user = %_{}) do
    if locked?(user, unlock_strategy()) do
      {:error, dgettext("haytni", "account is locked due to an excessive number of unsuccessful sign in attempts, please check your emails.")}
    else
      false
    end
  end

  @impl Haytni.Plugin
  def on_failed_authentification(user = %_{}, keywords) do
    strategy = unlock_strategy()
    if user.failed_attempts + 1 >= maximum_attempts() && !locked?(user, strategy)  do
      token = new_token()
      if strategy in ~W[both email]a do
        %{user | unlock_token: token}
        |> send_unlock_instructions_mail_to_user()
      end
      keywords
      |> Keyword.put(:locked_at, Haytni.now())
      |> Keyword.put(:unlock_token, token)
    else
      Keyword.put(keywords, :failed_attempts, user.failed_attempts + 1)
    end
  end

  @impl Haytni.Plugin
  def on_successful_authentification(conn = %Plug.Conn{}, user = %_{}, keywords) do
    # reset failed_attempts
    {conn, user, Keyword.put(keywords, :failed_attempts, 0)}
  end

  @doc ~S"""
  Returns `true` if *user* account is currently locked.
  """
  @spec locked?(user :: Haytni.user, strategy :: unlock_strategy) :: boolean
  def locked?(user = %_{}, strategy) do
    user.locked_at != nil && !lock_expired?(user, strategy)
  end

  @spec lock_expired?(user :: Haytni.user, strategy :: unlock_strategy) :: boolean
  def lock_expired?(user, strategy) do
    strategy in ~W[both time]a && DateTime.diff(DateTime.utc_now(), user.locked_at) >= Haytni.duration(unlock_in())
  end

  defp new_token do
    unlock_token_length()
    |> Haytni.Token.generate()
  end

  @spec send_unlock_instructions_mail_to_user(user :: Haytni.user) :: {:ok, Haytni.user}
  defp send_unlock_instructions_mail_to_user(user) do
    if email_strategy_enabled?() do
      Haytni.LockableEmail.unlock_instructions_email(user)
      |> Haytni.mailer().deliver_later()
    end
    {:ok, user}
  end

  @doc ~S"""
  Returns `true` if it's the last attempt before account locking in case of a new sign-in failure
  """
  @spec last_attempt?(user :: Haytni.user) :: boolean
  def last_attempt?(user = %_{}) do
    user.failed_attempts == maximum_attempts() - 1
  end

  @doc ~S"""
  Returns `true` if `:email` (included in `:both`) is enabled
  """
  @spec email_strategy_enabled?() :: boolean
  def email_strategy_enabled? do
    unlock_strategy() in ~W[both email]a
  end

  @doc ~S"""
  Unlock an account from a token.

  Returns the user if the token exists and `{:error, message}` if not.

  Also raises if updating user fails.
  """
  @spec unlock(token :: String.t) :: Haytni.user | {:error, String.t} | no_return
  def unlock(token) do
    if email_strategy_enabled?() do
      case Haytni.Users.get_user_by(unlock_token: token) do
        nil ->
          {:error, dgettext("haytni", "The given unlock token is invalid.")}
        user = %_{} ->
          Haytni.update_user_with!(user, unlock_token: nil, failed_attempts: 0, locked_at: nil)
      end
    else
      {:error, dgettext("haytni", "Unlocking accounts through email is currently disabled.")}
    end
  end

  @doc ~S"""
  Resend, by email, the instructions to unlock an account.

  Returns:

    * `{:error, :email_strategy_disabled}` if `:email` strategy is disabled
    * `{:error, :no_match}` if there is no such account matching `unlock_keys`
    * `{:error, :not_locked}` if the account is not currently locked
    * `{:ok, user}` if successful
  """
  @spec resend_unlock_instructions(request :: Haytni.Unlockable.Request.t) :: {:ok, Haytni.user} | {:error, :no_match | :not_locked | :email_strategy_disabled}
  def resend_unlock_instructions(request) do # request = %Haytni.Unlockable.Request{}
    if email_strategy_enabled?() do
      clauses = unlock_keys()
      |> Enum.into(Keyword.new(), fn key -> {key, Map.fetch!(request, key)} end)
      case Haytni.Users.get_user_by(clauses) do
        nil ->
          {:error, :no_match}
        %_{unlock_token: nil} ->
          {:error, :not_locked}
        user = %_{} ->
          user
          |> send_unlock_instructions_mail_to_user()
      end
    else
      {:error, :email_strategy_disabled}
    end
  end
end
