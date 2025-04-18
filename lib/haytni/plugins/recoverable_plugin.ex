defmodule Haytni.RecoverablePlugin do
  @default_password_path "/password"
  @password_path_key :password_path

  @default_reset_password_keys ~W[email]a
  @default_reset_password_within {6, :hour}

  @moduledoc """
  This plugin allows the user to reset its password if he forgot it. To do so, its email addresse (default) is asked to him then an unique token is generated
  and send to its mailbox. This mail contains a link to activate where a new password will be requested to override the previous one.

  Fields: none

  Configuration:

    * `reset_password_within` (default: `#{inspect(@default_reset_password_within)}`): the delay before the token expires
    * `reset_password_keys` (default: `#{inspect(@default_reset_password_keys)}`): the field(s) to be matched to send a reinitialization token

          stack #{inspect(__MODULE__)},
            reset_password_keys: #{inspect(@default_reset_password_keys)},
            reset_password_within: #{inspect(@default_reset_password_within)}

  Routes:

    * `haytni_<scope>_password_path` (actions: new/create, edit/update): default path is `#{inspect(@default_password_path)}` but you can customize it to whatever
      you want by specifying the option `#{inspect(@password_path_key)}` to your YourApp.Haytni.routes/1 call in your router (eg: `YourApp.Haytni.routes(#{@password_path_key}: "/recover")`)
  """

  use Gettext, backend: Haytni.Gettext

  defstruct [
    reset_password_keys: @default_reset_password_keys,
    reset_password_within: @default_reset_password_within,
  ]

  @type t :: %__MODULE__{
    reset_password_keys: [atom, ...],
    reset_password_within: Haytni.duration,
  }

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %__MODULE__{}
    |> Haytni.Helpers.merge_config(options, ~W[reset_password_within]a)
  end

  @impl Haytni.Plugin
  def files_to_install(_base_path, web_path, scope, _timestamp) do
    [
      # HTML
      {:eex, "phx17/views/password_html.ex", Path.join([web_path, "controllers", "haytni", scope, "password_html.ex"])},
      {:eex, "phx17/templates/password/new.html.heex", Path.join([web_path, "controllers", "haytni", scope, "password_html", "new.html.heex"])},
      {:eex, "phx17/templates/password/edit.html.heex", Path.join([web_path, "controllers", "haytni", scope, "password_html", "edit.html.heex"])},
      # email
      {:eex, "phx17/views/email/recoverable_emails.ex", Path.join([web_path, "emails", "haytni", scope, "recoverable_emails.ex"])},
      {:eex, "phx17/templates/email/recoverable/reset_password_instructions.html.heex", Path.join([web_path, "emails", "haytni", scope, "recoverable_html", "reset_password_instructions.html.heex"])},
      {:eex, "phx17/templates/email/recoverable/reset_password_instructions.text.eex", Path.join([web_path, "emails", "haytni", scope, "recoverable_text", "reset_password_instructions.text.eex"])},
    ]
  end

  @impl Haytni.Plugin
  def routes(_config, prefix_name, options) do
    prefix_name = :"#{prefix_name}_password"
    password_path = Keyword.get(options, @password_path_key, @default_password_path)
    quote bind_quoted: [prefix_name: prefix_name, password_path: password_path] do
      resources password_path, HaytniWeb.Recoverable.PasswordController, singleton: true, only: ~W[new create edit update]a, as: prefix_name
    end
  end

  use Haytni.Tokenable

  @impl Haytni.Tokenable
  def token_context(nil) do
    "recoverable"
  end

  @impl Haytni.Tokenable
  def expired_tokens_query(query, config) do
    import Ecto.Query

    from(
      t in query,
      where: not (t.context == ^token_context(nil) and t.inserted_at > ago(^config.reset_password_within, "second"))
    )
  end

  @doc ~S"""
  The (database) attributes as a keyword-list to redefine the password (after hashing) and void previous password recovery token
  """
  @spec new_password_attributes(module :: module, new_password :: String.t) :: Keyword.t
  def new_password_attributes(module, new_password) do
    config = module.fetch_config(Haytni.AuthenticablePlugin)

    [
      encrypted_password: Haytni.AuthenticablePlugin.hash_password(new_password, config),
    ]
  end

  @spec send_reset_password_instructions_mail_to_user(user :: Haytni.user, reset_password_token :: String.t, module :: module, config :: Haytni.config) :: Haytni.Mailer.DeliveryStrategy.email_sent
  defp send_reset_password_instructions_mail_to_user(user, reset_password_token, module, config) do
    email = Haytni.RecoverableEmail.reset_password_email(user, reset_password_token, module, config)
    Haytni.send_email(module, email)
  end

  @doc ~S"""
  Converts the parameters received by the controller from which users can start the password recovery procedure by requesting a
  recovery token into an `%Ecto.Changeset{}`.
  """
  @spec recovering_changeset(config :: t, request_params :: Haytni.params) :: Ecto.Changeset.t
  def recovering_changeset(config, request_params \\ %{}) do
    Haytni.Helpers.to_changeset(request_params, nil, config.reset_password_keys)
  end

  @spec send_instructions_in_multi(multi :: Ecto.Multi.t, user :: Haytni.user, token_name :: Ecto.Multi.name, module :: module, config :: t) :: Ecto.Multi.t
  defp send_instructions_in_multi(multi = %Ecto.Multi{}, user, token_name, module, config) do
    Ecto.Multi.run(
      multi,
      :send_reset_password_instructions,
      fn _repo, %{^token_name => token} ->
        send_reset_password_instructions_mail_to_user(user, Haytni.Token.url_encode(token), module, config)
        {:ok, true}
      end
    )
  end

  @doc ~S"""
  Send instructions to reset user's password.

  Returns:

    * `{:error, changeset}` if fields (form) were not filled
    * `{:ok, nil}` if there is no account matching `config.reset_password_keys`
    * `{:ok, token}` if successful
  """
  # step 1/2: send a token by mail
  @spec send_reset_password_instructions(module :: module, config :: t, request_params :: Haytni.params) :: {:ok, Haytni.Token.t | nil} | {:error, Ecto.Changeset.t}
  def send_reset_password_instructions(module, config, request_params) do
    changeset = recovering_changeset(config, request_params)

    changeset
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, sanitized_params} ->
        case Haytni.get_user_by(module, sanitized_params) do
          nil ->
            #Haytni.Helpers.mark_changeset_keys_as_unmatched(changeset, config.reset_password_keys)
            {:ok, nil}
          user = %_{} ->
            {:ok, %{token: token}} =
              Ecto.Multi.new()
              |> Haytni.Token.insert_token_in_multi(:token, user, user.email, token_context(nil))
              |> send_instructions_in_multi(user, :token, module, config)
              |> module.repo().transaction()
            {:ok, token}
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
  Change user's password from its recovering token.

  Returns `{:ok, user}` if successful else `{:error, changeset}` when the token:

    * is empty
    * doesn't exist
    * is expired
  """
  # step 2/2: update password
  @spec recover(module :: module, config :: t, password_params :: %{String.t => String.t}) :: {:ok, Haytni.user | nil} | {:error, Ecto.Changeset.t}
  def recover(module, config, password_params) do
    changeset = Haytni.Recoverable.PasswordChange.change_password(module, password_params)

    changeset
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, password_change} ->
        with(
          {:ok, recover_token} <- Haytni.Token.url_decode(password_change.reset_password_token),
          user = %_{} <- Haytni.Token.user_from_token_with_mail_match(module, recover_token, token_context(nil), config.reset_password_within)
        ) do
          {:ok, %{user: user}} =
            Ecto.Multi.new()
            |> Haytni.update_user_in_multi_with(:user, user, new_password_attributes(module, password_change.password))
            |> Haytni.Token.delete_tokens_in_multi(:tokens, user, token_context(nil))
            |> module.repo().transaction()
          {:ok, user}
        else
          _ ->
            set_reset_token_error(changeset, invalid_token_message())
        end
      error = {:error, %Ecto.Changeset{}} ->
        error
    end
  end
end
