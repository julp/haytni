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

          stack #{inspect(__MODULE__)},
            confirm_within: #{inspect(@default_confirm_within)},
            confirmation_keys: #{inspect(@default_confirmation_keys)},
            reconfirmable: #{inspect(@default_reconfirmable)},
            reconfirm_within: #{inspect(@default_reconfirm_within)}

  Routes:

    * `haytni_<scope>_confirmation_path` (actions: show, new/create): default path is `#{inspect(@default_confirmation_path)}` but it can be redefined by the
      `#{inspect(@confirmation_path_key)}` option when calling YourApp.Haytni.routes/1 from your own router (eg: `YourApp.Haytni.routes(#{@confirmation_path_key}: "/verification")`)
    * `haytni_<scope>_reconfirmation_path` (actions: show): default path is `#{inspect(@default_reconfirmation_path)}` (overridable by the option `#{inspect(@reconfirmation_path_key)}`)
  """

  import Haytni.Gettext

  defstruct [
    reconfirmable: @default_reconfirmable,
    confirm_within: @default_confirm_within,
    reconfirm_within: @default_reconfirm_within,
    confirmation_keys: @default_confirmation_keys,
  ]

  @type t :: %__MODULE__{
    confirm_within: Haytni.duration,
    confirmation_keys: [atom, ...],
    reconfirmable: boolean,
    reconfirm_within: Haytni.duration,
  }

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %__MODULE__{}
    |> Haytni.Helpers.merge_config(options, ~W[confirm_within reconfirm_within]a)
  end

  @impl Haytni.Plugin
  def files_to_install(_base_path, web_path, scope, timestamp) do
    if Haytni.Helpers.phoenix17?() do
      [
        # HTML
        {:eex, "phx17/views/confirmation_html.ex", Path.join([web_path, "controllers", "haytni", scope, "confirmation_html.ex"])},
        {:eex, "phx17/templates/confirmation/new.html.heex", Path.join([web_path, "controllers", "haytni", scope, "confirmation_html", "new.html.heex"])},
        # email
        {:eex, "phx17/views/email/confirmable_emails.ex", Path.join([web_path, "emails", "haytni", scope, "confirmable_emails.ex"])},
        {:eex, "phx17/templates/email/confirmable/email_changed.html.heex", Path.join([web_path, "emails", "haytni", scope, "confirmable_html", "email_changed.html.heex"])},
        {:eex, "phx17/templates/email/confirmable/confirmation_instructions.html.heex", Path.join([web_path, "emails", "haytni", scope, "confirmable_html", "confirmation_instructions.html.heex"])},
        {:eex, "phx17/templates/email/confirmable/reconfirmation_instructions.html.heex", Path.join([web_path, "emails", "haytni", scope, "confirmable_html", "reconfirmation_instructions.html.heex"])},
        {:eex, "phx17/templates/email/confirmable/email_changed.text.eex", Path.join([web_path, "emails", "haytni", scope, "confirmable_text", "email_changed.text.eex"])},
        {:eex, "phx17/templates/email/confirmable/confirmation_instructions.text.eex", Path.join([web_path, "emails", "haytni", scope, "confirmable_text", "confirmation_instructions.text.eex"])},
        {:eex, "phx17/templates/email/confirmable/reconfirmation_instructions.text.eex", Path.join([web_path, "emails", "haytni", scope, "confirmable_text", "reconfirmation_instructions.text.eex"])},
      ]
    # TODO: remove this when dropping support for Phoenix < 1.7
    else
      [
        # HTML
        {:eex, "phx16/views/confirmation_view.ex", Path.join([web_path, "views", "haytni", scope, "confirmation_view.ex"])},
        {:eex, "phx16/templates/confirmation/new.html.heex", Path.join([web_path, "templates", "haytni", scope, "confirmation", "new.html.heex"])},
        #{:text, "phx16/templates/confirmation/show.html.heex", Path.join([web_path, "templates", "haytni", scope, "confirmation", "show.html.heex"])},
        # email
        {:eex, "phx16/views/email/confirmable_view.ex", Path.join([web_path, "views", "haytni", scope, "email", "confirmable_view.ex"])},
        {:eex, "phx16/templates/email/confirmable/email_changed.text.eex", Path.join([web_path, "templates", "haytni", scope, "email", "confirmable", "email_changed.text.eex"])},
        {:eex, "phx16/templates/email/confirmable/email_changed.html.heex", Path.join([web_path, "templates", "haytni", scope, "email", "confirmable", "email_changed.html.heex"])},
        {:eex, "phx16/templates/email/confirmable/confirmation_instructions.text.eex", Path.join([web_path, "templates", "haytni", scope, "email", "confirmable", "confirmation_instructions.text.eex"])},
        {:eex, "phx16/templates/email/confirmable/confirmation_instructions.html.heex", Path.join([web_path, "templates", "haytni", scope, "email", "confirmable", "confirmation_instructions.html.heex"])},
        {:eex, "phx16/templates/email/confirmable/reconfirmation_instructions.text.eex", Path.join([web_path, "templates", "haytni", scope, "email", "confirmable", "reconfirmation_instructions.text.eex"])},
        {:eex, "phx16/templates/email/confirmable/reconfirmation_instructions.html.heex", Path.join([web_path, "templates", "haytni", scope, "email", "confirmable", "reconfirmation_instructions.html.heex"])},
      ]
    end ++ [
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
  def routes(_config, prefix_name, options) do
    # TODO: better to have only one controller (HaytniWeb.Confirmable.ConfirmationController) and add a custom action to it for reconfirmation?
    #prefix_name = :"#{prefix_name}_confirmation"
    confirmation_path = Keyword.get(options, @confirmation_path_key, @default_confirmation_path)
    reconfirmation_path = Keyword.get(options, @reconfirmation_path_key, @default_reconfirmation_path)
    quote bind_quoted: [prefix_name: prefix_name, confirmation_path: confirmation_path, reconfirmation_path: reconfirmation_path], unquote: true do
      resources confirmation_path, HaytniWeb.Confirmable.ConfirmationController, singleton: true, only: ~W[show new create]a, as: unquote(:"#{prefix_name}_confirmation")
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

  @spec handle_reconfirmable_for_multi(multi :: Ecto.Multi.t, module :: module, config :: t) :: Ecto.Multi.t
  defp handle_reconfirmable_for_multi(multi, _module, %__MODULE__{reconfirmable: false}), do: multi
  defp handle_reconfirmable_for_multi(multi, module, config = %__MODULE__{reconfirmable: true}) do
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
    |> Haytni.Token.insert_token_in_multi(:confirmation_token, :user, token_context(nil))
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

  use Haytni.Tokenable

  # NOTE: MUST only be used for confirmation, not reconfirmation (`"reconfirmable:" <> user.email`)
  @impl Haytni.Tokenable
  def token_context(nil) do
    "confirmable"
  end

  @context_reconfirmation_prefix "reconfirmable:"
  def token_context(old_email) do
    @context_reconfirmation_prefix <> old_email
  end

  @context_reconfirmation_pattern @context_reconfirmation_prefix <> "%"
  @impl Haytni.Tokenable
  def expired_tokens_query(query, config) do
    import Ecto.Query

    from(
      t in query,
      where: not (t.context == ^token_context(nil) and t.inserted_at > ago(^config.confirm_within, "second")),
      where: not (like(t.context, ^@context_reconfirmation_pattern) and t.inserted_at > ago(^config.reconfirm_within, "second"))
    )
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

  @spec send_confirmation_instructions(user :: Haytni.user, confirmation_token :: String.t, module :: module, config :: Haytni.config) :: Haytni.Mailer.DeliveryStrategy.email_sent
  defp send_confirmation_instructions(user, confirmation_token, module, config) do
    email = Haytni.ConfirmableEmail.confirmation_email(user, confirmation_token, module, config)
    Haytni.send_email(module, email)
  end

  @spec send_confirmation_instructions_in_multi(multi :: Ecto.Multi.t, user_or_user_name :: Haytni.user | Ecto.Multi.name, token_name :: Ecto.Multi.name, module :: module, config :: t) :: Ecto.Multi.t
  defp send_confirmation_instructions_in_multi(multi = %Ecto.Multi{}, user = %_{}, token_name, module, config) do
    Ecto.Multi.run(
      multi,
      :send_confirmation_instructions,
      fn _repo, %{^token_name => token} ->
        send_confirmation_instructions(user, Haytni.Token.url_encode(token), module, config)
        {:ok, true}
      end
    )
  end

  defp send_confirmation_instructions_in_multi(multi = %Ecto.Multi{}, user_name, token_name, module, config) do
    Ecto.Multi.run(
      multi,
      :send_confirmation_instructions,
      fn _repo, %{^user_name => user, ^token_name => token} ->
        send_confirmation_instructions(user, Haytni.Token.url_encode(token), module, config)
        {:ok, true}
      end
    )
  end

  @spec send_reconfirmation_instructions(user :: Haytni.user, unconfirmed_email :: String.t, confirmation_token :: String.t, module :: module, config :: Haytni.config) :: Haytni.Mailer.DeliveryStrategy.email_sent
  defp send_reconfirmation_instructions(user, unconfirmed_email, confirmation_token, module, config) do
    email = Haytni.ConfirmableEmail.reconfirmation_email(user, unconfirmed_email, confirmation_token, module, config)
    Haytni.send_email(module, email)
  end

  @spec send_reconfirmation_instructions_in_multi(multi :: Ecto.Multi.t, user_name :: Ecto.Multi.name, token_name :: Ecto.Multi.name, module :: module, config :: t) :: Ecto.Multi.t
  defp send_reconfirmation_instructions_in_multi(multi = %Ecto.Multi{}, user_name, token_name, module, config) do
    Ecto.Multi.run(
      multi,
      :send_reconfirmation_instructions,
      fn
        _repo, %{^user_name => nil} ->
          {:ok, false}
        _repo, %{^user_name => user, ^token_name => token, new_email: unconfirmed_email} ->
          send_reconfirmation_instructions(user, unconfirmed_email, Haytni.Token.url_encode(token), module, config)
          {:ok, true}
      end
    )
  end

  @spec send_notice_about_email_change(user :: Haytni.user, old_email :: String.t, module :: module, config :: t) :: Haytni.Mailer.DeliveryStrategy.email_sent
  defp send_notice_about_email_change(user = %_{}, old_email, module, config) do
    email = Haytni.ConfirmableEmail.email_changed(user, old_email, module, config)
    Haytni.send_email(module, email)
  end

  @spec send_notice_about_email_change_in_multi(multi :: Ecto.Multi.t, user_name :: Ecto.Multi.name, old_email_name :: Ecto.Multi.name, module :: module, config :: t) :: Ecto.Multi.t
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
  @spec confirmation_request_changeset(config :: t, confirmation_params :: Haytni.params) :: Ecto.Changeset.t
  def confirmation_request_changeset(config, confirmation_params \\ %{}) do
    Haytni.Helpers.to_changeset(confirmation_params, nil, [:referer | config.confirmation_keys], config.confirmation_keys)
  end

  @doc ~S"""
  Confirms an account from its confirmation *token*.

  Returns `{:error, reason}` if token is expired or invalid else the (updated) user as `{:ok, user}`.
  """
  @spec confirm(module :: module, config :: t, token :: String.t) :: {:ok, Haytni.user} | {:error, String.t}
  def confirm(module, config, token) do
    context = token_context(nil)
    with(
      {:ok, confirmation_token} <- Haytni.Token.url_decode(token),
      user = %_{} <- Haytni.Token.user_from_token_with_mail_match(module, confirmation_token, context, config.confirm_within)
    ) do
      {:ok, %{user: updated_user}} =
        Ecto.Multi.new()
        |> Haytni.update_user_in_multi_with(:user, user, confirmed_attributes())
        |> Haytni.Token.delete_tokens_in_multi(:tokens, user, context)
        |> module.repo().transaction()
      {:ok, updated_user}
    else
      _ ->
        {:error, invalid_token_message()}
    end
  end

  @doc ~S"""
  Reconfirms (validates an email address after its change) an account from its confirmation *token*.

  Returns `{:error, reason}` if token is expired or invalid else the (updated) user as `{:ok, user}`.
  """
  @spec reconfirm(module :: module, config :: t, user :: Haytni.user, token :: String.t) :: {:ok, Haytni.user} | {:error, String.t}
  def reconfirm(module, config, user, token) do
    context = token_context(user.email)
    with(
      {:ok, reconfirmation_token} <- Haytni.Token.url_decode(token),
      token = %_{} <- Haytni.Token.user_from_token_without_mail_match(module, user, reconfirmation_token, context, config.reconfirm_within)
    ) do
      {:ok, %{user: updated_user}} =
        Ecto.Multi.new()
        |> Haytni.update_user_in_multi_with(:user, user, email: token.sent_to)
        |> Haytni.Token.delete_tokens_in_multi(:tokens, user, context)
        |> module.repo().transaction()
      {:ok, updated_user}
    else
      _ ->
        {:error, invalid_token_message()}
    end
  end

  defp resend_confirmation_query(module, sanitized_params) do
    import Ecto.Query

    from(
      u in module.schema(),
      where: ^Map.to_list(sanitized_params),
      where: is_nil(u.confirmed_at)
    )
    |> module.repo().one()
  end

  @doc ~S"""
  Resend confirmation instructions to an email address (requested by its owner).

  Returns:

    * `{:ok, token}`: a token was actualy sent by mail
    * `{:ok, nil}`: there is no account matching `config.confirmation_keys` or the account is not pending confirmation
    * `{:error, changeset}`: fields (form) was invalid
  """
  @spec resend_confirmation_instructions(module :: module, config :: t, confirmation_params :: Haytni.params) :: {:ok, Haytni.nilable(Haytni.Token.t)} | {:error, Ecto.Changeset.t}
  def resend_confirmation_instructions(module, config, confirmation_params = %{}) do
    changeset = confirmation_request_changeset(config, confirmation_params)

    changeset
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, sanitized_params} ->
        sanitized_params = Map.delete(sanitized_params, :referer)
        case resend_confirmation_query(module, sanitized_params) do
          nil ->
            {:ok, nil}
          user = %_{} ->
            {:ok, %{token: token}} =
              Ecto.Multi.new()
              |> Haytni.Token.insert_token_in_multi(:token, user, user.email, token_context(nil))
              |> send_confirmation_instructions_in_multi(user, :token, module, config)
              |> module.repo().transaction()
            {:ok, token}
        end
      error = {:error, %Ecto.Changeset{}} ->
        error
    end
  end

  @doc ~S"""
  Allows a privilegied user (administrator) to manually confirm a user.

  Example: you could add a route in your administration panel:

  ```elixir
  scope "/admin" do
    pipe_through ~W[browser restricted_to_admin]a

    resources "/users" do
      resources "/confirm", YourAppWeb.Admin.User.ConfirmController, singleton: true, only: ~W[update]a
    end
  end
  ```

  With the above controller calling this function:

  ```elixir
  defmodule YourAppWeb.Admin.User.ConfirmController do
    def update(conn, %{"user_id" => user_id}) do
      user = YourApp.UserContext.get_user!(user_id)
      {:ok, user} = Haytni.ConfirmablePlugin.confirm_user(YourAppWeb.Haytni, user)

      conn
      |> put_flash(:info, "user has been confirmed")
      |> redirect(to: Routes.admin_user_path(conn, :index))
      |> halt()
    end
  end
  ```

  And do the link in your templates with:

  ```heex
  Status: <%= if Haytni.ConfirmablePlugin.confirmed?(user) do %>
    Confirmed
  <% else %>
    Not confirmed (<%= link "force confirmation?", to: Routes.admin_user_confirm_path(@conn, user, :update) %>)
  <% end %>
  ```
  """
  @spec confirm_user(module :: module, user :: Haytni.user) :: Haytni.repo_nobang_operation(Haytni.user)
  def confirm_user(module, user = %_{}) do
    Haytni.update_user_with(module, user, confirmed_attributes())
  end
end
