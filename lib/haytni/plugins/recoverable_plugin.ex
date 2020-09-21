defmodule Haytni.RecoverablePlugin do
  @default_password_path "/password"
  @password_path_key :password_path

  @default_reset_password_keys ~W[email]a
  @default_reset_password_within {6, :hour}
  @default_reset_token_length 32

  @moduledoc """
  This plugin allows the user to reset its password if he forgot it. To do so, its email addresse (default) is asked to him then an unique token is generated
  and send to its mailbox. This mail contains a link to activate where a new password will be requested to override the previous one.

  Fields:

    * reset_password_token (string, nullable, unique, default: `NULL`): the unique token to reinitialize the password (`NULL` if none)
    * reset_password_sent_at (datetime@utc, nullable, default: `NULL`): when the reinitialization token was generated (also `NULL` if there is no pending request)

  Configuration:

    * `reset_token_length` (default: `#{inspect(@default_reset_token_length)}`): the length of the generated token
    * `reset_password_within` (default: `#{inspect(@default_reset_password_within)}`): the delay before the token expires
    * `reset_password_keys` (default: `#{inspect(@default_reset_password_keys)}`): the field(s) to be matched to send a reinitialization token

          stack Haytni.RecoverablePlugin,
            reset_token_length: #{inspect(@default_reset_token_length)},
            reset_password_keys: #{inspect(@default_reset_password_keys)},
            reset_password_within: #{inspect(@default_reset_password_within)}

  Routes:

    * `haytni_<scope>_password_path` (actions: new/create, edit/update): default path is `#{inspect(@default_password_path)}` but you can customize it to whatever
      you want by specifying the option `#{inspect(@password_path_key)}` to your YourApp.Haytni.routes/1 call in your router (eg: `YourApp.Haytni.routes(#{@password_path_key}: "/recover")`)
  """

  import Haytni.Gettext

  defmodule Config do
    defstruct reset_password_within: {6, :hour}, reset_token_length: 32, reset_password_keys: ~W[email]a

    @type t :: %__MODULE__{
      reset_token_length: pos_integer,
      reset_password_keys: [atom, ...],
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
  def files_to_install(_base_path, web_path, scope, timestamp) do
    [
      # HTML
      {:eex, "views/password_view.ex", Path.join([web_path, "views", "haytni", scope, "password_view.ex"])},
      {:eex, "templates/password/new.html.eex", Path.join([web_path, "templates", "haytni", scope, "password", "new.html.eex"])},
      {:eex, "templates/password/edit.html.eex", Path.join([web_path, "templates", "haytni", scope, "password", "edit.html.eex"])},
      # email
      {:eex, "views/email/recoverable_view.ex", Path.join([web_path, "views", "haytni", scope, "email", "recoverable_view.ex"])},
      {:eex, "templates/email/recoverable/reset_password_instructions.text.eex", Path.join([web_path, "templates", "haytni", scope, "email", "recoverable", "reset_password_instructions.text.eex"])},
      {:eex, "templates/email/recoverable/reset_password_instructions.html.eex", Path.join([web_path, "templates", "haytni", scope, "email", "recoverable", "reset_password_instructions.html.eex"])},
      # migration
      {:eex, "migrations/0-recoverable_changes.exs", Path.join([web_path, "..", "..", "priv", "repo", "migrations", "#{timestamp}_haytni_recoverable_#{scope}_changes.exs"])},
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
  def routes(prefix_name, options) do
    prefix_name = :"#{prefix_name}_password"
    password_path = Keyword.get(options, @password_path_key, @default_password_path)
    quote bind_quoted: [prefix_name: prefix_name, password_path: password_path] do
      resources password_path, HaytniWeb.Recoverable.PasswordController, singleton: true, only: ~W[new create edit update]a, as: prefix_name
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

  @spec send_reset_password_instructions_mail_to_user(user :: Haytni.user, reset_password_token :: String.t, module :: module, config :: Haytni.config) :: {:ok, Haytni.irrelevant}
  defp send_reset_password_instructions_mail_to_user(user, reset_password_token, module, config) do
    user
    |> Haytni.RecoverableEmail.reset_password_email(reset_password_token, module, config)
    |> module.mailer().deliver_later()

    {:ok, true}
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

  But in strict mode (`config :haytni, mode: :strict`) returned values are:

    * `{:error, changeset}` if fields (form) were not filled
    * `{:ok, user}` if successful
    * `{:ok, nil}` if there is no account matching `config.reset_password_keys`

  For the latest, the difference between `{:ok, user}` and `{:ok, nil}` cases SHOULD not be tested in order to disclose
  to the end user if an actual account matches or not!
  """
  # step 1/2: send a token by mail
  @spec send_reset_password_instructions(module :: module, config :: Config.t, request_params :: %{optional(String.t) => String.t}) :: {:ok, nil | Haytni.user} | {:error, Ecto.Changeset.t}
  def send_reset_password_instructions(module, config, request_params) do
    changeset = recovering_changeset(config, request_params)

    changeset
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, sanitized_params} ->
        case Haytni.get_user_by(module, sanitized_params) do
          nil ->
            if Application.get_env(:haytni, :mode) == :strict do
              {:ok, nil}
            else
              Haytni.Helpers.mark_changeset_keys_as_unmatched(changeset, config.reset_password_keys)
            end
          user = %_{} ->
            Ecto.Multi.new()
            |> Ecto.Multi.update(:user, Ecto.Changeset.change(user, reset_password_attributes(config)))
            |> Ecto.Multi.run(
              :send_reset_password_instructions,
              fn _repo, %{user: user} ->
                send_reset_password_instructions_mail_to_user(user, user.reset_password_token, module, config)
              end
            )
            |> module.repo().transaction()
            |> case do
              {:ok, %{user: user}} -> {:ok, user}
              {:error, :user, changeset, _changes_so_far} -> {:error, changeset}
            end
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
        user = Haytni.get_user_by(module, [reset_password_token: password_change.reset_password_token])
        cond do
          is_nil(user) ->
            set_reset_token_error(changeset, invalid_token_message())
          reset_password_token_expired?(user, config) ->
            # TODO: would be more convenient to directly regenerate and send (email) a new one?
            set_reset_token_error(changeset, expired_token_message())
          true ->
            Haytni.update_user_with(module, user, new_password_attributes(module, password_change.password))
        end
      error = {:error, %Ecto.Changeset{}} ->
        error
    end
  end
end
