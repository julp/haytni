defmodule Haytni.ConfirmablePlugin do
  @default_confirmation_path "/confirmation"
  @confirmation_path_key :confirmation_path

  @default_reconfirmable true
  @default_confirm_within {3, :day}
  @default_confirmation_keys ~W[email]a
  @default_confirmation_token_length 32

  @moduledoc """
  This plugin ensure that email addresses given by users are valid by sending them an email containing an unique token that they have to
  return back in order to really be able to use (unlock) their account.

  On an email address change, it also warns the user by sending an email to the previous address and requests a confirmation, same as
  registering, to active in order to validate the change.

  Fields:

    * confirmed_at (datetime@utc, nullable, default: `NULL`): when the account was confirmed else `NULL`
    * confirmation_sent_at (datetime@utc): when the confirmation was sent
    * confirmation_token (string, nullable, unique, default: `NULL`): the token to be confirmed if any pending confirmation (else `NULL`)
    * unconfirmed_email (string, nullable, default: `NULL`): on email change the new email is stored here until its confirmation

  Configuration:

    * `reconfirmable` (default: `#{inspect(@default_reconfirmable)}`): any email changes have to be confirmed to be applied. Until confirmed, new email is stored in
      unconfirmed_email column, and copied to email column on successful confirmation
    * `confirmation_keys` (default: `#{inspect(@default_confirmation_keys)}`): the key(s) to be matched before sending a new confirmation
    * `confirm_within` (default: `#{inspect(@default_confirm_within)}`): delay after which confirmation token is considered as expired (ie the user has to ask for a new one)

          stack #{inspect(__MODULE__)},
            reconfirmable: #{inspect(@default_reconfirmable)},
            confirm_within: #{inspect(@default_confirm_within)},
            confirmation_keys: #{inspect(@default_confirmation_keys)},
            confirmation_token_length: #{inspect(@default_confirmation_token_length)}

  Routes:

    * `haytni_<scope>_confirmation_path` (actions: show, new/create): default path is `#{inspect(@default_confirmation_path)}` but it can be redefined by the
      `#{inspect(@confirmation_path_key)}` option when calling YourApp.Haytni.routes/1 from your own router (eg: `YourApp.Haytni.routes(#{@confirmation_path_key}: "/verification")`)
  """

  import Haytni.Gettext

  defmodule Config do
    defstruct reconfirmable: true,
      confirm_within: {3, :day},
      confirmation_token_length: 32,
      confirmation_keys: ~W[email]a

    @type t :: %__MODULE__{
      reconfirmable: boolean,
      confirm_within: Haytni.duration,
      confirmation_keys: [atom, ...],
      confirmation_token_length: pos_integer,
    }
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %Haytni.ConfirmablePlugin.Config{}
    |> Haytni.Helpers.merge_config(options, ~W[confirm_within]a)
  end

  @impl Haytni.Plugin
  def files_to_install(_base_path, web_path, scope, timestamp) do
    [
      # HTML
      {:eex, "views/confirmation_view.ex", Path.join([web_path, "views", "haytni", scope, "confirmation_view.ex"])},
      {:eex, "templates/confirmation/new.html.eex", Path.join([web_path, "templates", "haytni", scope, "confirmation", "new.html.eex"])},
      #{:text, "templates/confirmation/show.html.eex", Path.join([web_path, "templates", "haytni", scope, "confirmation", "show.html.eex"])},
      # email
      {:eex, "views/email/confirmable_view.ex", Path.join([web_path, "views", "haytni", scope, "email", "confirmable_view.ex"])},
      {:eex, "templates/email/confirmable/email_changed.text.eex", Path.join([web_path, "templates", "haytni", scope, "email", "confirmable", "email_changed.text.eex"])},
      {:eex, "templates/email/confirmable/email_changed.html.eex", Path.join([web_path, "templates", "haytni", scope, "email", "confirmable", "email_changed.html.eex"])},
      {:eex, "templates/email/confirmable/confirmation_instructions.text.eex", Path.join([web_path, "templates", "haytni", scope, "email", "confirmable", "confirmation_instructions.text.eex"])},
      {:eex, "templates/email/confirmable/confirmation_instructions.html.eex", Path.join([web_path, "templates", "haytni", scope, "email", "confirmable", "confirmation_instructions.html.eex"])},
      {:eex, "templates/email/confirmable/reconfirmation_instructions.text.eex", Path.join([web_path, "templates", "haytni", scope, "email", "confirmable", "reconfirmation_instructions.text.eex"])},
      {:eex, "templates/email/confirmable/reconfirmation_instructions.html.eex", Path.join([web_path, "templates", "haytni", scope, "email", "confirmable", "reconfirmation_instructions.html.eex"])},
      # migration
      {:eex, "migrations/0-confirmable_changes.exs", Path.join([web_path, "..", "..", "priv", "repo", "migrations", "#{timestamp}_haytni_confirmable_#{scope}_changes.exs"])},
    ]
  end

  @impl Haytni.Plugin
  def fields(_module) do
    quote do
      field :confirmed_at, :utc_datetime, default: nil # NULLABLE
      field :unconfirmed_email, :string, default: nil # NULLABLE # TODO: UNIQUE?
      field :confirmation_token, :string, default: nil # NULLABLE, UNIQUE
      field :confirmation_sent_at, :utc_datetime
    end
  end

  @impl Haytni.Plugin
  def routes(prefix_name, options) do
    prefix_name = :"#{prefix_name}_confirmation"
    confirmation_path = Keyword.get(options, @confirmation_path_key, @default_confirmation_path)
    quote bind_quoted: [prefix_name: prefix_name, confirmation_path: confirmation_path] do
      resources confirmation_path, HaytniWeb.Confirmable.ConfirmationController, singleton: true, only: ~W[show new create]a, as: prefix_name
    end
  end

  @doc ~S"""
  The translated string to display when account is on pending (re)confirmation.
  """
  @spec pending_confirmation_message() :: String.t
  def pending_confirmation_message do
    dgettext("haytni", "account is pending confirmation, please check your emails.")
  end

  @impl Haytni.Plugin
  def invalid?(user = %_{}, _module, _config) do
    if confirmed?(user) do
      false
    else
      {:error, pending_confirmation_message()}
    end
  end

  defp handle_reconfirmable_for_multi(multi, module, config) do
    if config.reconfirmable do
      multi
      |> Ecto.Multi.run(
        :send_reconfirmation_instructions,
        fn _repo, %{user: user} ->
          send_reconfirmation_instructions(user, module, config)
          {:ok, :success}
        end
      )
    else
      multi
    end
  end

  @impl Haytni.Plugin
  def on_email_change(multi, changeset, module, config) do
    multi =
      multi
      |> handle_reconfirmable_for_multi(module, config)
      |> Ecto.Multi.run(
        :send_notice_about_email_change,
        fn _repo, %{user: user, old_email: old_email} ->
          send_notice_about_email_change(user, old_email, module, config)
          {:ok, :success}
        end
      )

    changeset = if config.reconfirmable do
      changeset
      |> confirmation_changeset(config)
      |> Ecto.Changeset.put_change(:unconfirmed_email, Ecto.Changeset.get_change(changeset, :email))
      |> Ecto.Changeset.delete_change(:email)
    else
      changeset
    end

    {multi, changeset}
  end

  @impl Haytni.Plugin
  def validate_create_registration(changeset = %Ecto.Changeset{}, _module, config) do
    changeset
    |> confirmation_changeset(config)
  end

  @impl Haytni.Plugin
  def on_registration(multi = %Ecto.Multi{}, module, config) do
    Ecto.Multi.run(
      multi,
      :send_confirmation_instructions, fn _repo, %{user: user} ->
        send_confirmation_instructions(user, module, config)
        {:ok, :success}
      end
    )
  end

  @doc ~S"""
  Has the given user been confirmed?
  """
  @spec confirmed?(user :: Haytni.user) :: boolean
  def confirmed?(%_{confirmed_at: confirmed_at}) do
    confirmed_at != nil
  end

  defp confirm_handle_reconfirmation(_user = %_{unconfirmed_email: nil}, changes) do
    changes
  end

  defp confirm_handle_reconfirmation(user = %_{unconfirmed_email: _}, changes) do
    changes
    |> Keyword.put(:email, user.unconfirmed_email)
    |> Keyword.put(:unconfirmed_email, nil)
  end

  @doc ~S"""
  The translated string to display when (re)confirmation token is invalid (meaning matches no one)
  """
  @spec invalid_token_message() :: String.t
  def invalid_token_message do
    dgettext("haytni", "The given confirmation token is invalid.")
  end

  @doc ~S"""
  The translated string to display when (re)confirmation is expired
  """
  @spec expired_token_message() :: String.t
  def expired_token_message do
    dgettext("haytni", "The given confirmation token is expired, request a new one.")
  end

  @doc ~S"""
  Confirms an account from its (re)confirmation *token*.

  Returns `{:error, reason}` if token is expired or invalid else the (updated) user as `{:ok, user}`.
  """
  @spec confirm(module :: module, config :: Config.t, token :: String.t) :: {:ok, Haytni.user} | {:error, String.t}
  def confirm(module, config, token) do
    case Haytni.get_user_by(module, confirmation_token: token) do # AND confirmed_at IS NOT NULL?
      nil ->
        {:error, invalid_token_message()}
      user = %_{} ->
        if confirmation_token_expired?(user, config) do
          {:error, expired_token_message()}
        else
          Haytni.update_user_with(module, user, confirm_handle_reconfirmation(user, reset_confirmation_attributes()))
        end
    end
  end

  @spec confirmation_token_expired?(user :: Haytni.user, config :: Config.t) :: boolean
  defp confirmation_token_expired?(user, config) do
    DateTime.diff(DateTime.utc_now(), user.confirmation_sent_at) >= config.confirm_within
  end

  @doc ~S"""
  The (database) attributes as a keyword-list (field name: new value) to update a user as a confirmed account
  """
  @spec reset_confirmation_attributes() :: Keyword.t
  def reset_confirmation_attributes do
    [
      confirmation_token: nil,
      confirmed_at: Haytni.Helpers.now(),
    ]
  end

  @doc ~S"""
  The (database) attributes as a keyword-list to update a user as an account to be confirmed
  """
  @spec new_confirmation_attributes(config :: Config.t) :: Keyword.t
  def new_confirmation_attributes(config) do
    [
      confirmation_sent_at: Haytni.Helpers.now(),
      confirmation_token: Haytni.Token.generate(config.confirmation_token_length),
    ]
  end

  @doc ~S"""
  Add changes to *user_or_changeset* to mark the user as an account to be confirmed
  """
  @spec confirmation_changeset(user_or_changeset :: Haytni.user | Ecto.Changeset.t, config :: Config.t) :: Ecto.Changeset.t
  def confirmation_changeset(user_or_changeset, config) do
    user_or_changeset
    |> Ecto.Changeset.change(new_confirmation_attributes(config))
  end

  @spec send_confirmation_instructions(user :: Haytni.user, module :: module, config :: Haytni.config) :: {:ok, Haytni.irrelevant}
  defp send_confirmation_instructions(user, module, config) do
    user
    |> Haytni.ConfirmableEmail.confirmation_email(user.confirmation_token, module, config)
    |> module.mailer().deliver_later()

    {:ok, true}
  end

  @spec send_reconfirmation_instructions(user :: Haytni.user, module :: module, config :: Haytni.config) :: {:ok, Haytni.irrelevant}
  defp send_reconfirmation_instructions(user, module, config) do
    user
    |> Haytni.ConfirmableEmail.reconfirmation_email(user.unconfirmed_email, user.confirmation_token, module, config)
    |> module.mailer().deliver_later()

    {:ok, true}
  end

  @spec send_notice_about_email_change(user :: Haytni.user, old_email :: String.t, module :: module, config :: Config.t) :: {:ok, Bamboo.Email.t}
  defp send_notice_about_email_change(user = %_{}, old_email, module, config) do
    user
    |> Haytni.ConfirmableEmail.email_changed(old_email, module, config)
    |> module.mailer().deliver_later()
  end

  defp resend_handle_reconfirmation(nil, _module, _config) do
    {:ok, false}
  end

  defp resend_handle_reconfirmation(user = %_{unconfirmed_email: nil}, module, config) do
    user
    |> send_confirmation_instructions(module, config)
  end

  defp resend_handle_reconfirmation(user = %_{}, module, config) do
    #if config.reconfirmable do
      user
      |> send_reconfirmation_instructions(module, config)
    #else
      #{:error, :reconfirmable_disabled}
    #end
  end

  @doc ~S"""
  This function converts the parameters received by the controller to request a new confirmation token sent by email to an `%Ecto.Changeset{}`,
  a convenient way to perform basic validations, any intermediate handling and casting.
  """
  @spec confirmation_request_changeset(config :: Config.t, confirmation_params :: Haytni.params) :: Ecto.Changeset.t
  def confirmation_request_changeset(config, confirmation_params \\ %{}) do
    Haytni.Helpers.to_changeset(confirmation_params, [:referer | config.confirmation_keys], config.confirmation_keys)
  end

  @doc ~S"""
  The translated string to display when the account is already confirmed.
  """
  @spec alreay_confirmed_message() :: String.t
  def alreay_confirmed_message do
    dgettext("haytni", "This account has already been confirmed")
  end

  @spec handle_query_result_for_resend_confirmation(multi :: Ecto.Multi.t, mode :: any, user :: nil | Haytni.user, config :: Config.t, changeset :: Ecto.Changeset.t) :: Ecto.Multi.t
  defp handle_query_result_for_resend_confirmation(multi, :strict, nil, _config, _changeset) do
    Ecto.Multi.run(multi, :user, fn _repo, _changes -> {:ok, nil} end)
  end

  defp handle_query_result_for_resend_confirmation(multi, :strict, user = %_{confirmation_token: nil}, _config, _changeset) do
    Ecto.Multi.run(multi, :user, fn _repo, _changes -> {:ok, user} end)
  end

  defp handle_query_result_for_resend_confirmation(multi, _, nil, config, changeset) do
    Ecto.Multi.run(
      multi,
      :user,
      fn _repo, _changes ->
        Haytni.Helpers.mark_changeset_keys_as_unmatched(changeset, config.confirmation_keys)
      end
    )
  end

  defp handle_query_result_for_resend_confirmation(multi, _, %_{confirmation_token: nil}, config, changeset) do
    Ecto.Multi.run(
      multi,
      :user,
      fn _repo, _changes ->
        Haytni.Helpers.mark_changeset_keys_with_error(changeset, config.confirmation_keys, alreay_confirmed_message())
      end
    )
  end

  defp handle_query_result_for_resend_confirmation(multi, _, user, config, _changeset) do
    if confirmation_token_expired?(user, config) do
      Ecto.Multi.update(multi, :user, confirmation_changeset(user, config))
    else
      Ecto.Multi.run(multi, :user, fn _repo, _changes -> {:ok, user} end)
    end
  end

  @doc ~S"""
  Resend confirmation instructions to an email address (requested by its owner).

  Returns:

    * `{:error, changeset}` if there is no account matching `config.confirmation_keys` or if the account is not pending confirmation (`changeset.errors` will be set according)
    * `{:ok, user}` if successful

  But returned values differ in strict mode (`config :haytni, mode: :strict`):

    * `{:error, changeset}` if fields (form) were not filled
    * `{:ok, user}` if successful or nothing has to be done (meaning there is no account matching `config.confirmation_keys` or the account is not pending confirmation)
  """
  @spec resend_confirmation_instructions(module :: module, config :: Config.t, confirmation_params :: Haytni.params) :: Haytni.repo_nobang_operation(Haytni.user | nil)
  def resend_confirmation_instructions(module, config, confirmation_params = %{}) do
    changeset = confirmation_request_changeset(config, confirmation_params)

    changeset
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, sanitized_params} ->
        sanitized_params = Map.delete(sanitized_params, :referer)
        user = if config.reconfirmable and :email in config.confirmation_keys do
          import Ecto.Query
          # if config.reconfirmable and email is used as key to resend confirmation then rewrite:
          # email = ?
          # to:
          # ? IN(email, unconfirmed_email)
          module.schema()
          |> from(where: ^Enum.to_list(Map.delete(sanitized_params, :email)))
          |> where(fragment("? IN(email, unconfirmed_email)", type(^sanitized_params.email, :string)))
          |> module.repo().one()
        else
          Haytni.get_user_by(module, sanitized_params)
        end

        Ecto.Multi.new()
        |> handle_query_result_for_resend_confirmation(Application.get_env(:haytni, :mode), user, config, changeset)
        |> Ecto.Multi.run(
          :resend_confirmation_instructions,
          fn _repo, %{user: user} ->
            resend_handle_reconfirmation(user, module, config)
          end
        )
        |> module.repo().transaction()
        |> case do
          {:ok, %{user: user}} -> {:ok, user}
          {:error, :user, changeset, _changes_so_far} -> {:error, changeset}
        end
      error = {:error, %Ecto.Changeset{}} ->
        error
    end
  end
end
