defmodule Haytni.ConfirmablePlugin do
  @moduledoc ~S"""
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

    * `reconfirmable` (default: `true`): any email changes have to be confirmed to be applied. Until confirmed, new email is stored in
      unconfirmed_email column, and copied to email column on successful confirmation
    * `confirmation_keys` (default: `~W[email]a`): the key(s) to be matched before sending a new confirmation
    * `confirm_within` (default: `{3, :day}`): delay after which confirmation token is considered as expired (ie the user has to ask for a new one)

  Routes:

    * `confirmation_path` (actions: show, new/create)
  """

  import Haytni.Gettext

  use Haytni.Plugin
  use Haytni.Config, [
    reconfirmable: true,
    confirm_within: {3, :day},
    confirmation_token_length: 32,
    confirmation_keys: ~W[email]a
  ]

  @impl Haytni.Plugin
  def files_to_install do
    import Mix.Tasks.Haytni.Install, only: [web_path: 0, timestamp: 0]
    [
      # HTML
      {:eex, "views/confirmation_view.ex", Path.join([web_path(), "views", "haytni", "confirmation_view.ex"])},
      {:eex, "templates/confirmation/new.html.eex", Path.join([web_path(), "templates", "haytni", "confirmation", "new.html.eex"])},
      #{:text, "templates/confirmation/show.html.eex", Path.join([web_path(), "templates", "haytni", "confirmation", "show.html.eex"])},
      # email
      {:eex, "views/email/confirmable_view.ex", Path.join([web_path(), "views", "haytni", "email", "confirmable_view.ex"])},
      {:eex, "templates/email/confirmable/email_changed.text.eex", Path.join([web_path(), "templates", "haytni", "email", "confirmable", "email_changed.text.eex"])},
      {:eex, "templates/email/confirmable/email_changed.html.eex", Path.join([web_path(), "templates", "haytni", "email", "confirmable", "email_changed.html.eex"])},
      {:eex, "templates/email/confirmable/confirmation_instructions.text.eex", Path.join([web_path(), "templates", "haytni", "email", "confirmable", "confirmation_instructions.text.eex"])},
      {:eex, "templates/email/confirmable/confirmation_instructions.html.eex", Path.join([web_path(), "templates", "haytni", "email", "confirmable", "confirmation_instructions.html.eex"])},
      {:eex, "templates/email/confirmable/reconfirmation_instructions.text.eex", Path.join([web_path(), "templates", "haytni", "email", "confirmable", "reconfirmation_instructions.text.eex"])},
      {:eex, "templates/email/confirmable/reconfirmation_instructions.html.eex", Path.join([web_path(), "templates", "haytni", "email", "confirmable", "reconfirmation_instructions.html.eex"])},
      # migration
      {:eex, "migrations/confirmable_changes.ex", Path.join([web_path(), "..", "..", "priv", "repo", "migrations", "#{timestamp()}_haytni_confirmable_changes.ex"])} # TODO: less "hacky"
    ]
  end

  @impl Haytni.Plugin
  def fields do
    quote do
      field :confirmed_at, :utc_datetime, default: nil # NULLABLE
      field :unconfirmed_email, :string, default: nil # NULLABLE # TODO: UNIQUE?
      field :confirmation_token, :string, default: nil # NULLABLE, UNIQUE
      field :confirmation_sent_at, :utc_datetime
    end
  end

  @impl Haytni.Plugin
  def routes(_scope, _options) do
    quote do
      resources "/confirmation", HaytniWeb.Confirmable.ConfirmationController, singleton: true, only: ~W[show new create]a
    end
  end

  @impl Haytni.Plugin
  def invalid?(user = %_{}) do
    if confirmed?(user) do
      false
    else
      {:error, dgettext("haytni", "account is pending confirmation, please check your emails.")}
    end
  end

  defp handle_reconfirmable_for_multi(multi, true) do
    multi
    |> Ecto.Multi.run(:send_reconfirmation_instructions, fn %{user: user} ->
      send_reconfirmation_instructions(user)
      {:ok, :success}
    end)
  end
  defp handle_reconfirmable_for_multi(multi, _), do: multi

  @impl Haytni.Plugin
  def on_email_change(multi, changeset) do
    multi = multi
    |> handle_reconfirmable_for_multi(reconfirmable())
    |> Ecto.Multi.run(:send_notice_about_email_change, fn %{user: user, old_email: old_email} ->
      send_notice_about_email_change(user, old_email)
      {:ok, :success}
    end)

    changeset = if reconfirmable() do
      changeset
      |> Ecto.Changeset.change(new_confirmation())
      |> Ecto.Changeset.put_change(:unconfirmed_email, Ecto.Changeset.get_change(changeset, :email))
      |> Ecto.Changeset.delete_change(:email)
    else
      changeset
    end

    {multi, changeset}
  end

  @impl Haytni.Plugin
  def validate_create_registration(changeset = %Ecto.Changeset{}) do
    changeset
    |> Ecto.Changeset.change(new_confirmation())
  end

  @impl Haytni.Plugin
  def on_registration(multi = %Ecto.Multi{}) do
    Ecto.Multi.run(multi, :send_confirmation_instructions, fn %{user: user} ->
      send_confirmation_instructions(user)
      {:ok, :success}
    end)
  end

  @doc ~S"""
  Has the given user been confirmed?
  """
  @spec confirmed?(user :: struct) :: boolean
  def confirmed?(%_{confirmed_at: confirmed_at}) do
    confirmed_at != nil
  end

  defp confirm_handle_reconfirmation(_user = %{unconfirmed_email: nil}, changes) do
    changes
  end

  defp confirm_handle_reconfirmation(user = %{unconfirmed_email: _}, changes) do
    changes
    |> Keyword.put(:email, user.unconfirmed_email)
    |> Keyword.put(:unconfirmed_email, nil)
  end

  @doc ~S"""
  Confirms an account from its (confirmation) token.

  Returns `{:error, reason}` if token is expired or invalid else the (updated) user.

  Raises if the user could not be updated.
  """
  @spec confirm(token :: String.t) :: struct | {:error, String.t} | no_return
  def confirm(token) do
    case Haytni.Users.get_user_by(confirmation_token: token) do # AND confirmed_at IS NOT NULL?
      nil ->
        {:error, dgettext("haytni", "The given confirmation token is invalid.")}
      user = %_{} ->
        if confirmation_token_expired?(user) do
          {:error, dgettext("haytni", "The given confirmation token is expired, request a new one.")}
        else
          Haytni.update_user_with!(user, confirm_handle_reconfirmation(user, confirmation_token: nil, confirmed_at: DateTime.utc_now()))
        end
    end
  end

  @spec confirmation_token_expired?(user :: struct) :: boolean
  defp confirmation_token_expired?(user) do
    DateTime.diff(DateTime.utc_now(), user.confirmation_sent_at) >= Haytni.duration(confirm_within())
  end

  @spec new_confirmation() :: Keyword.t
  defp new_confirmation do
    [confirmation_sent_at: DateTime.utc_now(), confirmation_token: new_token()]
  end

  @spec new_token() :: String.t
  defp new_token do
    confirmation_token_length()
    |> Haytni.Token.generate()
  end

  @spec send_confirmation_instructions(user :: struct) :: {:ok, struct}
  defp send_confirmation_instructions(user) do
    #Task.start(
      #fn ->
        Haytni.ConfirmableEmail.confirmation_email(user)
        |> Haytni.mailer().deliver_later()
      #end
    #)
    {:ok, user}
  end

  @spec send_reconfirmation_instructions(user :: struct) :: {:ok, struct}
  defp send_reconfirmation_instructions(user) do
    Haytni.ConfirmableEmail.reconfirmation_email(user)
    |> Haytni.mailer().deliver_later()
    {:ok, user}
  end

  @spec send_notice_about_email_change(user :: struct, old_email :: String.t) :: Bamboo.Email.t
  defp send_notice_about_email_change(user = %_{}, old_email) do
    Haytni.ConfirmableEmail.email_changed(user, old_email)
    |> Haytni.mailer().deliver_later()
  end

  defp resend_handle_reconfirmation(user = %_{unconfirmed_email: nil}) do
    user
    |> send_confirmation_instructions()
  end

  defp resend_handle_reconfirmation(user = %_{}) do
    #if reconfirmable() do
      user
      |> send_reconfirmation_instructions()
    #else
      #{:error, :reconfirmable_disabled}
    #end
  end

  @doc ~S"""
  Resend confirmation instructions to an email address (requested by its owner).

  Returns:

    * `{:error, :no_match}` if there is no account matching `confirmation_keys`
    * `{:error, :already_confirmed}` if the account is not pending confirmation
    * `{:ok, user}` if successful

  Raises if user couldn't be updated.
  """
  @spec resend_confirmation_instructions(confirmation :: Haytni.Confirmation.t) :: {:ok, struct} | {:error, :no_match | :already_confirmed} | no_return
  def resend_confirmation_instructions(confirmation) do
    clauses = confirmation_keys()
    |> Enum.into(Keyword.new(), fn key -> {key, Map.fetch!(confirmation, key)} end)
    user = if reconfirmable() && :email in confirmation_keys() do
      import Ecto.Query
      # if reconfirmable and email is used as key to resend confirmation then rewrite:
      # email = ?
      # to:
      # ? IN(email, unconfirmed_email)
      Haytni.schema()
      |> from(where: ^Keyword.delete(clauses, :email))
      |> where(fragment("? IN(email, unconfirmed_email)", type(^confirmation.email, :string)))
      |> Haytni.repo().one()
    else
      Haytni.Users.get_user_by(clauses)
    end
    case user do
      nil ->
        {:error, :no_match}
      %_{confirmation_token: nil} ->
        {:error, :already_confirmed}
      user = %_{} ->
        if confirmation_token_expired?(user) do
          user
          |> Haytni.update_user_with!(new_confirmation())
        else
          user
        end
        |> resend_handle_reconfirmation()
    end
  end
end
