defmodule Haytni.ConfirmablePlugin do
  @default_confirmation_path "/confirmation"
  @confirmation_path_key :confirmation_path
  @default_reconfirmation_path "/reconfirmation"
  @reconfirmation_path_key :reconfirmation_path

  @default_reconfirmable true
  @default_confirm_within {3, :day}
  @default_reconfirm_within @default_confirm_within
  @default_confirmation_keys ~W[email]a

  @moduledoc """
  This plugin ensure that email addresses given by users are valid by sending them an email containing an unique token that they have to
  return back in order to really be able to use (unlock) their account.

  On an email address change, it also warns the user by sending an email to the previous address and requests a confirmation, same as
  registering, to active in order to validate the change.

  Fields:

    * confirmed_at (datetime@utc, nullable, default: `NULL`): when the account was confirmed else `NULL`

  Configuration:

    * `reconfirmable` (default: `#{inspect(@default_reconfirmable)}`): any email changes have to be confirmed to be applied
    * `confirmation_keys` (default: `#{inspect(@default_confirmation_keys)}`): the key(s) to be matched before sending a new confirmation
    * `confirm_within` (default: `#{inspect(@default_confirm_within)}`): delay after which confirmation token is considered as expired (ie the user has to ask for a new one)

          stack Haytni.ConfirmablePlugin,
            confirm_within: #{inspect(@default_confirm_within)},
            confirmation_keys: #{inspect(@default_confirmation_keys)},
            reconfirmable: #{inspect(@default_reconfirmable)},
            reconfirm_within: #{inspect(@default_reconfirm_within)}

  Routes:

    * `haytni_<scope>_confirmation_path` (actions: show, new/create): default path is `#{inspect(@default_confirmation_path)}` but it can be redefined by the
      `#{inspect(@confirmation_path_key)}` option when calling YourApp.Haytni.routes/1 from your own router (eg: `YourApp.Haytni.routes(#{@confirmation_path_key}: "/verification")`)
    * `haytni_<scope>_reconfirmation_path` (actions: show): TODO
  """

  import Haytni.Gettext

  defmodule Config do
    defstruct confirm_within: {3, :day},
      confirmation_keys: ~W[email]a,
      reconfirmable: true,
      reconfirm_within: {3, :day}

    @type t :: %__MODULE__{
      confirm_within: Haytni.duration,
      confirmation_keys: [atom, ...],
      reconfirmable: boolean,
      reconfirm_within: Haytni.duration,
    }
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %Haytni.ConfirmablePlugin.Config{}
    |> Haytni.Helpers.merge_config(options, ~W[confirm_within reconfirm_within]a)
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
    end
  end

  @impl Haytni.Plugin
  def routes(prefix_name, options) do
    #prefix_name = :"#{prefix_name}_confirmation"
    confirmation_path = Keyword.get(options, @confirmation_path_key, @default_confirmation_path)
    reconfirmation_path = Keyword.get(options, @reconfirmation_path_key, @default_reconfirmation_path)
    quote bind_quoted: [prefix_name: prefix_name, confirmation_path: confirmation_path, reconfirmation_path: reconfirmation_path], unquote: true do
      resources confirmation_path, HaytniWeb.Confirmable.ConfirmationController, singleton: true, only: ~W[show new create]a, as: unquote(:"#{prefix_name}_confirmation")
      # TODO: prefix (préférable de garder un contrôleur et de jouer sur l'action ?)
      resources reconfirmation_path, HaytniWeb.Confirmable.ReconfirmationController, singleton: true, only: ~W[show]a, as: unquote(:"#{prefix_name}_reconfirmation")
    end
  end

  @impl Haytni.Plugin
  def invalid?(user = %_{}, _module, _config) do
    if confirmed?(user) do
      false
    else
      {:error, pending_confirmation_message()}
    end
  end

  @spec handle_reconfirmable_for_multi(multi :: Ecto.Multi.t, module :: module, config :: Config.t) :: Ecto.Multi.t
  defp handle_reconfirmable_for_multi(multi, _module, %Config{reconfirmable: false}), do: multi
  defp handle_reconfirmable_for_multi(multi, module, config = %Config{reconfirmable: true}) do
    multi
    |> Ecto.Multi.insert(
      :confirmation_token,
      fn %{user: user, old_email: old_email, new_email: new_email} ->
        Haytni.Token.build_and_assoc_token(user, new_email, token_context(old_email))
      end
    )
    |> send_reconfirmation_instructions_in_multi(:user, :confirmation_token, module, config)
  end

  @impl Haytni.Plugin
  def on_email_change(multi, changeset, module, config) do
    multi =
      multi
      |> handle_reconfirmable_for_multi(module, config)
      |> send_notice_about_email_change_in_multi(:user, :old_email, module, config)

    changeset = if config.reconfirmable do
      Ecto.Changeset.delete_change(changeset, :email)
    else
      changeset
    end

    {multi, changeset}
  end

  @impl Haytni.Plugin
  def on_registration(multi = %Ecto.Multi{}, module, config) do
    multi
    |> Haytni.Token.insert_token_in_multi(:confirmation_token, :user, token_context())
    |> send_confirmation_instructions_in_multi(:user, :confirmation_token, module, config)
  end

  @doc ~S"""
  Has the given user been confirmed?
  """
  @spec confirmed?(user :: Haytni.user) :: boolean
  def confirmed?(%_{confirmed_at: confirmed_at}) do
    confirmed_at != nil
  end

  @doc ~S"""
  The translated string to display when account is on pending (re)confirmation.
  """
  @spec pending_confirmation_message() :: String.t
  def pending_confirmation_message do
    dgettext("haytni", "account is pending confirmation, please check your emails.")
  end

  @doc ~S"""
  The translated string to display when (re)confirmation token is invalid (meaning matches no one)
  """
  @spec invalid_token_message() :: String.t
  def invalid_token_message do
    dgettext("haytni", "The given confirmation token is invalid or has expired.")
  end

  @doc ~S"""
  The translated string to display when the account is already confirmed.
  """
  @spec alreay_confirmed_message() :: String.t
  def alreay_confirmed_message do
    dgettext("haytni", "This account has already been confirmed")
  end

  use Haytni.Tokenable

  # NOTE: MUST only be used for confirmation, not reconfirmation ("reconfirmable:" <> user.email)
  #@spec token_context() :: String.t
  @impl Haytni.Tokenable
  def token_context do
    "confirmable"
  end

  @context_reconfirmation_prefix "reconfirmable:"
  @spec token_context(old_email :: String.t) :: String.t
  def token_context(old_email) do
    @context_reconfirmation_prefix <> old_email
  end

  @context_reconfirmation_pattern @context_reconfirmation_prefix <> "%"
  @impl Haytni.Tokenable
  def expired_tokens_query(config) do
    [
      "context == #{token_context()} AND inserted_at > ago(#{config.confirm_within}, \"second\")",
      "context LIKE 'reconfirmable:%' AND inserted_at > ago(#{config.reconfirm_within}, \"second\")",
    ]
    import Ecto.Query

    conditions = dynamic([t], t.context == ^token_context() and t.inserted_at > ago(^config.confirm_within, "second"))
    _conditions = dynamic([t], ^conditions or like(t.context, ^@context_reconfirmation_pattern) and t.inserted_at > ago(^config.reconfirm_within, "second"))
  end

  @doc ~S"""
  The (database) attribute(s) as a keyword-list (field name: new value) to update a user as a confirmed account
  """
  @spec confirmed_attributes() :: Keyword.t
  def confirmed_attributes do
    [
      confirmed_at: Haytni.Helpers.now(),
    ]
  end

  @spec send_confirmation_instructions(user :: Haytni.user, confirmation_token :: String.t, module :: module, config :: Haytni.config) :: Bamboo.Email.t
  defp send_confirmation_instructions(user, confirmation_token, module, config) do
    user
    |> Haytni.ConfirmableEmail.confirmation_email(confirmation_token, module, config)
    |> module.mailer().deliver_later()
  end

  @spec send_confirmation_instructions_in_multi(multi :: Ecto.Multi.t, user_name :: Ecto.Multi.name, token_name :: Ecto.Multi.name, module :: module, config :: Config.t) :: Ecto.Multi.t
  defp send_confirmation_instructions_in_multi(multi = %Ecto.Multi{}, user_name, token_name, module, config) do
    Ecto.Multi.run(
      multi,
      :send_confirmation_instructions,
      fn _repo, %{^user_name => user, ^token_name => token} ->
        send_confirmation_instructions(user, Haytni.Token.encode_token(token), module, config)
        {:ok, true}
      end
    )
  end

  @spec send_reconfirmation_instructions(user :: Haytni.user, unconfirmed_email :: String.t, confirmation_token :: String.t, module :: module, config :: Haytni.config) :: Bamboo.Email.t
  defp send_reconfirmation_instructions(user, unconfirmed_email, confirmation_token, module, config) do
    user
    |> Haytni.ConfirmableEmail.reconfirmation_email(unconfirmed_email, confirmation_token, module, config)
    |> module.mailer().deliver_later()
  end

  @spec send_reconfirmation_instructions_in_multi(multi :: Ecto.Multi.t, user_name :: Ecto.Multi.name, token_name :: Ecto.Multi.name, module :: module, config :: Config.t) :: Ecto.Multi.t
  defp send_reconfirmation_instructions_in_multi(multi = %Ecto.Multi{}, user_name, token_name, module, config) do
    Ecto.Multi.run(
      multi,
      :send_reconfirmation_instructions,
      fn
        _repo, %{^user_name => nil} ->
          {:ok, false}
        _repo, %{^user_name => user, ^token_name => token, new_email: unconfirmed_email} ->
          send_reconfirmation_instructions(user, unconfirmed_email, Haytni.Token.encode_token(token), module, config)
          {:ok, true}
      end
    )
  end

  @spec send_notice_about_email_change(user :: Haytni.user, old_email :: String.t, module :: module, config :: Config.t) :: Bamboo.Email.t
  defp send_notice_about_email_change(user = %_{}, old_email, module, config) do
    user
    |> Haytni.ConfirmableEmail.email_changed(old_email, module, config)
    |> module.mailer().deliver_later()
  end

  @spec send_notice_about_email_change_in_multi(multi :: Ecto.Multi.t, user_name :: Ecto.Multi.name, old_email_name :: Ecto.Multi.name, module :: module, config :: Config.t) :: Ecto.Multi.t
  defp send_notice_about_email_change_in_multi(multi, user_name, old_email_name, module, config) do
    Ecto.Multi.run(
      multi,
      :send_notice_about_email_change,
      fn _repo, %{^user_name => user, ^old_email_name => old_email} ->
        send_notice_about_email_change(user, old_email, module, config)
        {:ok, true}
      end
    )
  end

  @doc ~S"""
  This function converts the parameters received by the controller to request a new confirmation token sent by email to an `%Ecto.Changeset{}`,
  a convenient way to perform basic validations, any intermediate handling and casting.
  """
  @spec confirmation_request_changeset(config :: Config.t, confirmation_params :: Haytni.params) :: Ecto.Changeset.t
  def confirmation_request_changeset(config, confirmation_params \\ %{}) do
    Haytni.Helpers.to_changeset(confirmation_params, [:referer | config.confirmation_keys], config.confirmation_keys)
  end

  @spec handle_query_result_for_resend_confirmation(multi :: Ecto.Multi.t, mode :: any, user :: nil | Haytni.user, config :: Config.t, changeset :: Ecto.Changeset.t) :: Ecto.Multi.t
  # no user matches confirmation_keys but, in strict mode, do not disclose it
  defp handle_query_result_for_resend_confirmation(multi, :strict, user = nil, _config, _changeset) do
    Haytni.Multi.assign(multi, :user, user)
  end

  # no user matches confirmation_keys but, in NON-strict mode, disclose it
  defp handle_query_result_for_resend_confirmation(multi, _, nil, config, changeset) do
    Ecto.Multi.run(
      multi,
      :user,
      fn _repo, _changes ->
        Haytni.Helpers.mark_changeset_keys_as_unmatched(changeset, config.confirmation_keys)
      end
    )
  end

  defp handle_query_result_for_resend_confirmation(multi, _, %_{confirmed_at: confirmed_at}, config, changeset)
    when not is_nil(confirmed_at)
  do
    Ecto.Multi.run(
      multi,
      :user,
      fn _repo, _changes ->
        Haytni.Helpers.mark_changeset_keys_with_error(changeset, config.confirmation_keys, alreay_confirmed_message())
      end
    )
  end

  # a user matches confirmation_keys
  defp handle_query_result_for_resend_confirmation(multi, _, user, _config, _changeset) do
    Haytni.Multi.assign(multi, :user, user)
  end

  @doc ~S"""
  Confirms an account from its confirmation *token*.

  Returns `{:error, reason}` if token is expired or invalid else the (updated) user as `{:ok, user}`.
  """
  @spec confirm(module :: module, config :: Config.t, token :: String.t) :: Haytni.multi_result
  def confirm(module, config, token) do
    context = token_context()
    case Haytni.Token.user_from_token_with_mail_match(module, token, context, config.confirm_within) do
      nil ->
        {:error, invalid_token_message()} # TODO: conversion en Multi
      user = %_{} ->
        Ecto.Multi.new()
        |> Haytni.update_user_in_multi_with(:user, user, confirmed_attributes())
        |> Haytni.Token.delete_tokens_in_multi(:tokens, user, context)
        |> module.repo().transaction()
    end
  end

  @doc ~S"""
  TODO
  """
  @spec reconfirm(module :: module, config :: Config.t, user :: Haytni.user, token :: String.t) :: Haytni.multi_result
  def reconfirm(module, config, user, confirmation_token) do
    # TODO: refactoriser ce qui est commun avec confirm ci-dessus ?
    context = token_context(user.email)
    with(
      {:ok, confirmation_token} <- Haytni.Token.decode_token(confirmation_token),
      token = %_{} <- Haytni.Token.user_from_token_without_mail_match(module, user, confirmation_token, context, config.reconfirm_within)
    ) do
        Ecto.Multi.new()
        |> Haytni.update_user_in_multi_with(:user, user, email: token.sent_to)
        |> Haytni.Token.delete_tokens_in_multi(:tokens, user, context)
        |> module.repo().transaction()
    else
      _ ->
        {:error, invalid_token_message()} # TODO: conversion en Multi
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
  @spec resend_confirmation_instructions(module :: module, config :: Config.t, confirmation_params :: Haytni.params) :: Haytni.multi_result
  def resend_confirmation_instructions(module, config, confirmation_params = %{}) do
    changeset = confirmation_request_changeset(config, confirmation_params)

    changeset
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, sanitized_params} ->
        sanitized_params = Map.delete(sanitized_params, :referer)
        # TODO: incorporer ça en multi ? (avec where: is_nil(u.confirmed_at) ?)
        user = Haytni.get_user_by(module, sanitized_params)
        Ecto.Multi.new()
        |> handle_query_result_for_resend_confirmation(Application.get_env(:haytni, :mode), user, config, changeset)
        |> Haytni.Token.insert_token_in_multi(:token, :user, token_context())
        |> send_confirmation_instructions_in_multi(:user, :token, module, config)
        |> module.repo().transaction()
      error = {:error, %Ecto.Changeset{}} ->
        error
    end
  end
end
