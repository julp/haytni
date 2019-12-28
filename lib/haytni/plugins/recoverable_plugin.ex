defmodule Haytni.RecoverablePlugin do
  @moduledoc ~S"""
  This plugin allows the user to reset its password if he forgot it. To do so, its email addresse (default) is asked to him then an unique token is generated
  and send to its mailbox. This mail contains a link to activate where a new password will be requested to override the previous one.

  Fields:

    * reset_password_token (string, nullable, unique, default: `NULL`): the unique token to reinitialize the password (`NULL` if none)
    * reset_password_sent_at (datetime@utc, nullable, default: `NULL`): when the reinitialization token was generated (also `NULL` if there is no pending request)

  Configuration:

    * `reset_token_length` (default: `32`): the length of the generated token
    * `reset_password_within` (default: `{6, :hour}`): the delay before the token expires
    * `reset_password_keys` (default: `~W[email]a`): the field(s) to be matched to send a reinitialization token

          config :haytni, Haytni.RecoverablePlugin,
            reset_token_length: 32,
            reset_password_keys: ~W[email]a,
            reset_password_within: {6, :hour}

  Routes:

    * `password_path` (actions: new/create, edit/update)
  """

  import Haytni.Gettext

  defmodule Config do
    defstruct reset_password_within: {6, :hour}, reset_token_length: 32, reset_password_keys: ~W[email]a

    @type t :: %__MODULE__{
      reset_token_length: pos_integer,
      reset_password_keys: [atom],
      reset_password_within: Haytni.duration,
    }
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %Haytni.RecoverablePlugin.Config{}
    |> Haytni.Helpers.merge_config(options, ~W[reset_password_within]a)
  end

  @impl Haytni.Plugin
  def files_to_install do
    import Mix.Tasks.Haytni.Install, only: [web_path: 0, timestamp: 0]
    [
      # HTML
      {:eex, "views/password_view.ex", Path.join([web_path(), "views", "haytni", "password_view.ex"])},
      {:eex, "templates/password/new.html.eex", Path.join([web_path(), "templates", "haytni", "password", "new.html.eex"])},
      {:eex, "templates/password/edit.html.eex", Path.join([web_path(), "templates", "haytni", "password", "edit.html.eex"])},
      # email
      {:eex, "views/email/recoverable_view.ex", Path.join([web_path(), "views", "haytni", "email", "recoverable_view.ex"])},
      {:eex, "templates/email/recoverable/reset_password_instructions.text.eex", Path.join([web_path(), "templates", "haytni", "email", "recoverable", "reset_password_instructions.text.eex"])},
      {:eex, "templates/email/recoverable/reset_password_instructions.html.eex", Path.join([web_path(), "templates", "haytni", "email", "recoverable", "reset_password_instructions.html.eex"])},
      # migration
      {:eex, "migrations/0-recoverable_changes.ex", Path.join([web_path(), "..", "..", "priv", "repo", "migrations", "#{timestamp()}_haytni_recoverable_changes.ex"])}, # TODO: less "hacky"
    ]
  end

  @impl Haytni.Plugin
  def fields(_module) do
    quote do
      field :reset_password_token, :string, default: nil # NULLABLE, UNIQUE
      field :reset_password_sent_at, :utc_datetime, default: nil # NULLABLE
    end
  end

  @impl Haytni.Plugin
  def routes(_options) do
    quote do
      resources "/password", HaytniWeb.Recoverable.PasswordController, as: :password, singleton: true, only: ~W[new create edit update]a
    end
  end

  @doc ~S"""
  The (database) attributes as a keyword-list to generate a new password recovery token
  """
  @spec reset_password_attributes(config :: Config.t) :: Keyword.t
  def reset_password_attributes(config) do
    [
      reset_password_sent_at: Haytni.Helpers.now(),
      reset_password_token: Haytni.Token.generate(config.reset_token_length),
    ]
  end

  @doc ~S"""
  The (database) attributes as a keyword-list to redefine the password (after hashing) and void previous password recovery token
  """
  @spec new_password_attributes(module :: module, new_password :: String.t) :: Keyword.t
  def new_password_attributes(module, new_password) do
    config = module.fetch_config(Haytni.AuthenticablePlugin)
    [
      reset_password_token: nil,
      reset_password_sent_at: nil,
      encrypted_password: Haytni.AuthenticablePlugin.hash_password(new_password, config),
    ]
  end

  @spec send_reset_password_instructions_mail_to_user(user :: Haytni.user, module :: module, config :: Haytni.config) :: {:ok, Haytni.user}
  defp send_reset_password_instructions_mail_to_user(user, module, config) do
    Haytni.RecoverableEmail.reset_password_email(user, module, config)
    |> module.mailer().deliver_later()
    {:ok, user}
  end

  @spec reset_password_token_expired?(user :: Haytni.user, config :: Config.t) :: boolean
  defp reset_password_token_expired?(user, config) do
    DateTime.diff(DateTime.utc_now(), user.reset_password_sent_at) >= config.reset_password_within
  end

  @doc ~S"""
  Converts the parameters received by the controller from which users can start the password recovery procedure by requesting a
  recovery token into an `%Ecto.Changeset{}`.
  """
  @spec recovering_changeset(config :: Config.t, request_params :: %{optional(String.t) => String.t}) :: Ecto.Changeset.t
  def recovering_changeset(config, request_params \\ %{}) do
    Haytni.Helpers.to_changeset(request_params, config.reset_password_keys)
  end

  @doc ~S"""
  Send instructions to reset user's password.

  Returns `{:error, changeset}` if there is no account matching `config.reset_password_keys` else `{:ok, user}`.

  Raises if user couldn't be updated.
  """
  # step 1/2: send a token by mail
  @spec send_reset_password_instructions(module :: module, config :: Config.t, request_params :: %{optional(String.t) => String.t}) :: {:ok, Haytni.user} | {:error, Ecto.Changeset.t} | no_return
  def send_reset_password_instructions(module, config, request_params) do
    changeset = recovering_changeset(config, request_params)

    changeset
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, sanitized_params} ->
        case Haytni.get_user_by(module, sanitized_params) do
          nil ->
            Haytni.Helpers.mark_changeset_keys_as_unmatched(changeset, config.reset_password_keys)
          user = %_{} ->
            # TODO: use Ecto.Multi?
            Haytni.update_user_with!(module, user, reset_password_attributes(config)) # NOTE: this line implies no_return in spec
            |> send_reset_password_instructions_mail_to_user(module, config)
        end
      error = {:error, %Ecto.Changeset{}} ->
        error
    end
  end

  @spec set_reset_token_error(changeset :: Ecto.Changeset.t, error :: String.t) :: {:error, Ecto.Changeset.t}
  defp set_reset_token_error(changeset, error) do
    changeset
    |> Ecto.Changeset.add_error(:reset_password_token, error)
    |> Ecto.Changeset.apply_action(:insert)
  end

  @doc ~S"""
  The translated string to display when a password recovery token is invalid (ie not associated to someone)
  """
  @spec invalid_token_message() :: String.t
  def invalid_token_message do
    dgettext("haytni", "The given password recovery token is invalid.")
  end

  @doc ~S"""
  The translated string to display when a password recovery token exists but is expired
  """
  @spec expired_token_message() :: String.t
  def expired_token_message do
    dgettext("haytni", "The given password recovery token is expired.")
  end

  @doc ~S"""
  Change user's password from its recovering token.

  Returns `{:ok, user}` if successful else `{:error, changeset}` when the token:

    * is empty
    * doesn't exist
    * is expired
  """
  # step 2/2: update password
  @spec recover(module :: module, config :: Config.t, password_params :: %{String.t => String.t}) :: {:ok, Haytni.user} | {:error, Ecto.Changeset.t}
  def recover(module, config, password_params) do
    changeset = Haytni.Recoverable.PasswordChange.change_password(module, password_params)

    changeset
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, password_change} ->
        case Haytni.get_user_by(module, [reset_password_token: password_change.reset_password_token]) do
          nil ->
            set_reset_token_error(changeset, invalid_token_message())
          user = %_{} ->
            if reset_password_token_expired?(user, config) do
              # TODO: would be more convenient to directly regenerate and send (email) a new one?
              set_reset_token_error(changeset, expired_token_message())
            else
              Haytni.update_user_with(module, user, new_password_attributes(module, password_change.password))
            end
        end
      error = {:error, %Ecto.Changeset{}} ->
        error
    end
  end
end
