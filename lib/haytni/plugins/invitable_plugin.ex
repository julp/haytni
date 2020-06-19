defmodule Haytni.InvitablePlugin do
  # config
  @default_invitation_required true
  @default_invitation_quota :infinity
  @default_invalidation_within {30, :day}
  @default_email_matching_invitation false
  # paths
  @default_invitation_path "/invitations"
  @invitation_path_key :invitation_path

  @moduledoc """
  This plugin provides the feature of registration on invitation or sponsorship.

  Fields: none

  Configuration:

    * `invitation_quota` (default: `#{inspect(@default_invitation_quota)}`): the maximum amount of invitation a user can send. Possible values:
      + `:infinity` if illimited
      + `{count, :total}`, *count* being a number, to restrict the user to a total of *count* invitation
      + `{count, :unaccepted}`, *count* being a number, to limit the user to *count* pending invitation
    * `email_matching_invitation` (default: `#{inspect(@default_email_matching_invitation)}`): `true` to force users who accept the invitation to register with the same email address they received the invitation from
    * `invitation_required` (default: `#{inspect(@default_invitation_required)}`): `true` if users can only register with a valid invitation. `false` to make it optional (sponsorship).
    * `invitation_within` (default: `#{inspect(@default_invalidation_within)}`): laps of time before the invitation can no longer be used (expiration)
    * `invitation_sent_to_index_name` (default: `nil`): the name of the index on sent_to column if you have to explicit it

          stack Haytni.InvitablePlugin,
            invitation_required: #{inspect(@default_invitation_required)},
            invitation_quota: #{inspect(@default_invitation_quota)},
            invitation_within: #{inspect(@default_invalidation_within)},
            email_matching_invitation: #{inspect(@default_email_matching_invitation)},
            invitation_sent_to_index_name: nil

  Routes:

    * `haytni_<scope>_invitation_path` (actions: new/create): default path is `#{inspect(@default_invitation_path)}` but you can customize it to whatever you want by specifying
      the option `#{inspect(@invitation_path_key)}` to your YourApp.Haytni.routes/1 call in your router (eg: `YourApp.Haytni.routes(#{@invitation_path_key}: "/sponsorship")`)
  """

  import Haytni.Gettext

  @type invitation :: struct

  defmodule Config do
    defstruct invitation_quota: :infinity,
      email_matching_invitation: false,
      invitation_required: true,
      invitation_within: {30, :day},
      invitation_sent_to_index_name: nil

    @type t :: %__MODULE__{
      invitation_quota: :infinity | {pos_integer, :total | :unaccepted},
      email_matching_invitation: boolean,
      invitation_required: boolean,
      invitation_within: Haytni.duration,
      invitation_sent_to_index_name: atom | String.t | nil,
    }
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %Haytni.InvitablePlugin.Config{}
    |> Haytni.Helpers.merge_config(options, ~W[invitation_within]a)
  end

  @impl Haytni.Plugin
  def files_to_install(_base_path, web_path, scope, timestamp) do
    [
      # HTML
      {:eex, "views/invitation_view.ex", Path.join([web_path, "views", "haytni", scope, "invitation_view.ex"])},
      {:eex, "templates/invitation/new.html.eex", Path.join([web_path, "templates", "haytni", scope, "invitation", "new.html.eex"])},
      # email
      {:eex, "views/email/invitable_view.ex", Path.join([web_path, "views", "haytni", scope, "email", "invitable_view.ex"])},
      {:eex, "templates/email/invitable/invitation.text.eex", Path.join([web_path, "templates", "haytni", scope, "email", "invitable", "invitation.text.eex"])},
      {:eex, "templates/email/invitable/invitation.html.eex", Path.join([web_path, "templates", "haytni", scope, "email", "invitable", "invitation.html.eex"])},
      # migration
      {:eex, "migrations/0-invitable_creation.exs", Path.join([web_path, "..", "..", "priv", "repo", "migrations", "#{timestamp}_haytni_invitable_#{scope}_creation.exs"])},
    ]
  end

  def __after_compile__(env, _bytecode) do
    contents = quote do
      use Ecto.Schema
      import Ecto.Changeset

      schema "#{unquote(env.module.__schema__(:source))}_invitations" do
        field :code, :string # UNIQUE
        field :sent_to, :string # UNIQUE
        field :sent_at, :utc_datetime
        field :accepted_at, :utc_datetime # NULLABLE

        belongs_to :sender, unquote(env.module), foreign_key: :sent_by
        belongs_to :accepter, unquote(env.module), foreign_key: :accepted_by # NULLABLE
      end

      @attributes ~W[sent_to]a
      def changeset(config, invitation = %__MODULE__{}, params \\ %{}) do
        invitation
        |> cast(params, @attributes)
        |> validate_required(@attributes)
        # TODO: reuse, move or share code from Haytni.RegisterablePlugin and its config.email_regexp
        |> Ecto.Changeset.validate_format(:sent_to, ~R/^[^@\s]+@[^@\s]+$/)
        #|> Ecto.Changeset.unsafe_validate_unique(:sent_to)
        |> Ecto.Changeset.unique_constraint(:sent_to, name: config.invitation_sent_to_index_name)
      end
    end

    Module.create(env.module.__schema__(:association, :invitations).related, contents, env)
  end

  @impl Haytni.Plugin
  def fields(_module) do
    quote bind_quoted: [] do
      @after_compile Haytni.InvitablePlugin

      field :invitation, :string, default: nil, virtual: true

      has_many :invitations, Haytni.Helpers.scope_module(__MODULE__, "Invitation"), foreign_key: :sent_by
    end
  end

  @impl Haytni.Plugin
  def routes(prefix_name, options) do
    prefix_name = :"#{prefix_name}_invitation"
    invitation_path = Keyword.get(options, @invitation_path_key, @default_invitation_path)
    quote bind_quoted: [prefix_name: prefix_name, invitation_path: invitation_path] do
      resources invitation_path, HaytniWeb.Invitable.InvitationController, only: ~W[new create]a, as: prefix_name
    end
  end

  @doc ~S"""
  The translated string set as error when invitation are required but any was provided
  """
  @spec invitation_required_message() :: String.t
  def invitation_required_message do
    dgettext("haytni", "you can't register without having received an invitation")
  end

  @doc ~S"""
  The translated string set as error when invitation token does not exist
  """
  @spec invalid_invitation_message() :: String.t
  def invalid_invitation_message do
    dgettext("haytni", "the given invitation does not exist")
  end

  @doc ~S"""
  The translated string set as error when invitation has expired
  """
  @spec invitation_expired_message() :: String.t
  def invitation_expired_message do
    dgettext("haytni", "the given invitation has expired")
  end

  @doc ~S"""
  The translated string set as error when email address does not match the invitation
  """
  @spec invitation_email_mismatch_message() :: String.t
  def invitation_email_mismatch_message do
    dgettext("haytni", "the given email address mismatch the invitation it was sent to")
  end

  @doc ~S"""
  The translated string set as error when invitation quota is exceeded
  """
  @spec invitation_quota_exceeded_message(count :: pos_integer) :: String.t
  def invitation_quota_exceeded_message(count) do
    dgettext("haytni", "your quota of %{count} invitation(s) has been exceeded", count: count)
  end

  defp invitation_expired?(invitation, config) do
    DateTime.diff(DateTime.utc_now(), invitation.sent_at) >= config.invitation_within
  end

  defmodule QueryHelpers do
    @moduledoc ~S"""
    This module provides some basic helpers to query invitations to be independant and not
    have to know the internals of the Invitable plugin.
    """

    import Ecto.Query

    @doc ~S"""
    Returns a queryable for all invitations sent by *user*
    """
    def invitations_from_user(user = %_{}) do
      from(i in Ecto.assoc(user, :invitations), as: :invitations)
    end

    @doc ~S"""
    Returns a queryable for all invitations

    Note: *user* is not used for the query, just to find the scope/table/association
    """
    def invitations_from_all(user = %_{}) do
      from(i in user.__struct__.__schema__(:association, :invitations).related, as: :invitations)
    end

    @doc ~S"""
    Composes *query* to filter on non-accepted invitations
    """
    def and_where_not_accepted(query) do
      from(i in query, where: is_nil(i.accepted_by))
    end

    @doc ~S"""
    Composes *query* to filter on accepted invitations
    """
    def and_where_accepted(query) do
      from(i in query, where: not is_nil(i.accepted_by))
    end

    @doc ~S"""
    Composes *query* to filter on non-expired invitations
    """
    def and_where_not_expired(query, config) do
      from(i in query, where: i.sent_at > ago(^config.invitation_within, "second"))
    end

    @doc ~S"""
    Composes *query* for token invitation to match *code*
    """
    def and_where_code_equals(query, code)
      when is_binary(code) # exclude code = nil
    do
      from(i in query, where: i.code == ^code) # not is_nil(^code) and ...
    end

    @doc ~S"""
    Composes *query* for invitation id (primary key) to worth *id*
    """
    def and_where_id_equals(query, id)
      when not is_nil(id)
    do
      from(i in query, where: i.id == ^id)
    end

    @doc ~S"""
    Composes *query* for *email* to match the address it was sent to only if
    `email_matching_invitation` is `true` (else returns the query as it was)
    """
    def and_where_email_equals(query, email, config)
      when is_binary(email) # exclude email = nil
    do
      if config.email_matching_invitation do
        from(i in query, where: i.sent_to == ^email)
      else
        query
      end
    end
  end

  @spec validate_invitation(changeset :: Ecto.Changeset.t, config :: Config.t) :: Ecto.Changeset.t
  defp validate_invitation(changeset = %Ecto.Changeset{valid?: true, changes: %{invitation: code}}, config)
    when not is_nil(code)
  do
    changeset.data
    |> QueryHelpers.invitations_from_all()
    |> QueryHelpers.and_where_code_equals(code)
    |> QueryHelpers.and_where_not_accepted()
    |> changeset.repo.one()
    |> case do
      nil ->
        # TODO: ignore if config.invitation_required = false?
        Haytni.Helpers.add_base_error(changeset, invalid_invitation_message())
      invitation ->
        cond do
          invitation_expired?(invitation, config) ->
            # TODO: ignore if config.invitation_required = false?
            Haytni.Helpers.add_base_error(changeset, invitation_expired_message())
          config.email_matching_invitation && invitation.sent_to != Ecto.Changeset.get_change(changeset, :email) ->
            # TODO: ignore if config.invitation_required = false?
            Haytni.Helpers.add_base_error(changeset, invitation_email_mismatch_message())
          true ->
            changeset
        end
    end
  end

  defp validate_invitation(changeset = %Ecto.Changeset{valid?: false, changes: %{invitation: _}}, _config) do
    changeset
  end

  defp validate_invitation(changeset, %Config{invitation_required: true}) do
    Haytni.Helpers.add_base_error(changeset, invitation_required_message())
  end

  defp validate_invitation(changeset, _config), do: changeset

  @impl Haytni.Plugin
  def validate_create_registration(changeset = %Ecto.Changeset{}, config) do
    changeset
    |> Ecto.Changeset.prepare_changes(
      fn changeset ->
        validate_invitation(changeset, config)
      end
    )
  end

  @impl Haytni.Plugin
  def on_registration(multi = %Ecto.Multi{}, _module, config) do
    multi
    |> Ecto.Multi.run(:acceptation, fn repo, %{user: user} ->
      {count, nil} = if not is_nil(user.invitation) do
        user
        |> QueryHelpers.invitations_from_all()
        |> QueryHelpers.and_where_not_accepted()
        |> QueryHelpers.and_where_code_equals(user.invitation)
        |> QueryHelpers.and_where_not_expired(config)
        |> QueryHelpers.and_where_email_equals(user.email, config)
        |> repo.update_all(set: [accepted_at: Haytni.Helpers.now(), accepted_by: user.id])
      else
        {0, nil}
      end
      if config.invitation_required and count != 1 do
        {:error, :invitation_required}
      else
        {:ok, count == 1}
      end
    end)
  end

  @spec send_invitation_mail(user :: Haytni.user, invitation :: invitation, module :: module, config :: Config.t) :: {:ok, Haytni.irrelevant}
  defp send_invitation_mail(user, invitation, module, config) do
    Haytni.InvitableEmail.invitation_email(user, invitation, module, config)
    |> module.mailer().deliver_later()

    {:ok, true}
  end

  if false do
    @doc ~S"""
    This function converts the parameters received by the controller to send a new invitation by email to an `%Ecto.Changeset{}`,
    a convenient way to perform basic validations, any intermediate handling and casting.
    """
    @spec invitation_changeset(config :: Config.t, invitation_params :: %{optional(String.t) => String.t}) :: Ecto.Changeset.t
    def invitation_changeset(_config, invitation_params \\ %{}) do
      Haytni.Helpers.to_changeset(invitation_params, ~W[email]a)
      # TODO: reuse, move or share code from Haytni.RegisterablePlugin, config.email_regexp
      |> Ecto.Changeset.validate_format(:email, ~R/^[^@\s]+@[^@\s]+$/)
    end
  end

  defp check_quota(_changeset, _repo, _user, :infinity), do: {:ok, false}
  defp check_quota(_changeset = %Ecto.Changeset{valid?: false}, _repo, _user, _count), do: {:ok, false}

  defp check_quota(changeset, repo, user, {count, :total}) do
    Ecto.assoc(user, :invitations)
    |> set_quota_exceeded_error(repo, changeset, count)
  end

  defp check_quota(changeset, repo, user, {count, :unaccepted}) do
    user
    |> QueryHelpers.invitations_from_user()
    |> QueryHelpers.and_where_not_accepted()
    |> set_quota_exceeded_error(repo, changeset, count)
  end

  defp set_quota_exceeded_error(query, repo, changeset, count) do
    query
    |> repo.aggregate(:count)
    |> Kernel.>=(count)
    |> if do
      changeset
      |> Haytni.Helpers.apply_base_error(invitation_quota_exceeded_message(count))
    else
      {:ok, true}
    end
  end

  @doc ~S"""
  Build an invitation associated to *user*.

  Valid attributes (keys) for *attrs* are:

    * `:code` (required): the unique token associated to the invitation
    * `:sent_at` (required): when (`DateTime`) the invitation was sent
    * `:sent_to` (required): the email address the invitation was sent to
    * `:accepted_by` (for testing purpose only): the id of the user who accepted the invitation
    * `:accepted_at` (for testing purpose only): when (`DateTime`) the invitation was accepted
    * `:id` (for testing purpose only): force a (not nil) id for an in-memory (not persisted to database) invitation
  """
  @spec build_and_assoc_invitation(user :: Haytni.user, attrs :: Keyword.t | Map.t) :: invitation
  def build_and_assoc_invitation(user, attrs \\ %{}) do
    Ecto.build_assoc(user, :invitations, attrs)
  end

  @doc ~S"""
  Converts an invitation to an `Ecto.Changeset` by applying the changes from *params*
  """
  @spec invitation_to_changeset(invitation :: invitation, config :: Config.t, params :: %{optional(String.t) => String.t}) :: Ecto.Changeset.t
  def invitation_to_changeset(invitation, config, params \\ %{}) do
    invitation.__struct__.changeset(config, invitation, params)
  end

  @doc ~S"""
  Resend (email) an invitation

  Note: there is no checking and invitation.sender must have been preloaded
  """
  @spec resend_information(module :: module, config :: Config.t, invitation :: invitation) :: {:ok, true}
  def resend_information(module, config, invitation) do
    send_invitation_mail(invitation.sender, invitation, module, config)
  end

  @doc ~S"""
  Sends an invitation (by email) from *user* after checking if its quota (`invitation_quota`) allows it to
  """
  @spec send_invitation(module :: module, config :: Config.t, invitation_params :: %{optional(String.t) => String.t}, user :: Haytni.user) :: {:ok, invitation} | {:error, Ecto.Changeset.t}
  def send_invitation(module, config, invitation_params, user) do
    changeset = user
    |> build_and_assoc_invitation(code: Haytni.Token.generate(64), sent_at: Haytni.Helpers.now())
    |> invitation_to_changeset(config, invitation_params)
    Ecto.Multi.new()
    |> Ecto.Multi.run(
      :quota_check,
      fn repo, _changes ->
        check_quota(changeset, repo, user, config.invitation_quota)
      end
    )
    |> Ecto.Multi.insert(:invitation, changeset)
    |> Ecto.Multi.run(
      :invitation_email,
      fn _repo, %{invitation: invitation} ->
        send_invitation_mail(user, invitation, module, config)
      end
    )
    |> module.repo().transaction()
    |> case do
      {:ok, %{invitation: invitation}} -> {:ok, invitation}
      {:error, _, changeset = %Ecto.Changeset{}, _} -> {:error, changeset}
    end
  end
end
