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

  Routes:

    * `password_path` (actions: new/create, edit/update)
  """

  #import Plug.Conn
  #import Ecto.Changeset
  import Haytni.Gettext

  use Haytni.Plugin
  use Haytni.Config, [
    reset_token_length: 32,
    reset_password_keys: ~W[email]a,
    reset_password_within: {6, :hour}
  ]

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
      {:eex, "migrations/recoverable_changes.ex", Path.join([web_path(), "..", "..", "priv", "repo", "migrations", "#{timestamp()}_haytni_recoverable_changes.ex"])} # TODO: less "hacky"
    ]
  end

  @impl Haytni.Plugin
  def fields do
    quote do
      field :reset_password_token, :string, default: nil # NULLABLE, UNIQUE
      field :reset_password_sent_at, :utc_datetime, default: nil # NULLABLE
    end
  end

  @impl Haytni.Plugin
  def routes(_scope, _options) do
    quote do
      resources "/password", HaytniWeb.Recoverable.PasswordController, as: :password, singleton: true, only: ~W[new create edit update]a
    end
  end

  @spec new_token() :: String.t
  defp new_token do
    reset_token_length()
    |> Haytni.Token.generate()
  end

  @spec send_reset_password_instructions_mail_to_user(user :: struct) :: Bamboo.Email.t
  defp send_reset_password_instructions_mail_to_user(user) do
    Haytni.RecoverableEmail.reset_password_email(user)
    |> Haytni.mailer().deliver_later()
    {:ok, user}
  end

  @spec reset_password_token_expired?(user :: struct) :: boolean
  defp reset_password_token_expired?(user) do
    DateTime.diff(DateTime.utc_now(), user.reset_password_sent_at) >= Haytni.duration(reset_password_within())
  end

  @doc ~S"""
  Send instructions to reset user's password.

  Returns `{:error, :no_match}` if there is no account matching `reset_password_keys` else `{:ok, user}`.

  Raises if user couldn't be updated.
  """
  # step 1/2: send a token by mail
  @spec send_reset_password_instructions(request :: Haytni.Recoverable.ResetRequest.t) :: {:ok, struct} | {:error, :no_match}
  def send_reset_password_instructions(request) do # request = %ResetRequest{}
    clauses = reset_password_keys()
    |> Enum.into(Keyword.new(), fn key -> {key, Map.fetch!(request, key)} end)
    case Haytni.Users.get_user_by(clauses) do
      nil ->
        {:error, :no_match}
      user = %_{} ->
        user
        |> Haytni.update_user_with!(reset_password_token: new_token(), reset_password_sent_at: DateTime.utc_now())
        |> send_reset_password_instructions_mail_to_user()
    end
  end

  @doc ~S"""
  Change user's password from its recovering token.

  Returns `{:error, reason}` if the token doesn't exist or has expired else the user.

  Also raises if user couldn't be updated.
  """
  # step 2/2: update password
  @spec recover(token :: String.t, new_password :: String.t) :: struct | {:error, String.t} | no_return
  def recover(token, new_password) do
    case Haytni.Users.get_user_by(reset_password_token: token) do
      nil ->
        {:error, dgettext("haytni", "The given reset token is invalid.")}
      user = %_{} ->
        if reset_password_token_expired?(user) do
          # TODO: would be more convenient to directly regenerate and send (email) a new one?
          {:error, dgettext("haytni", "The given reset token is expired.")}
        else
          user
          |> Haytni.update_user_with!([reset_password_sent_at: nil, reset_password_token: nil, encrypted_password: Haytni.AuthenticablePlugin.hash_password(new_password)])
        end
    end
  end
end
