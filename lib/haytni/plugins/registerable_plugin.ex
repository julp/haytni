defmodule Haytni.RegisterablePlugin do
  @default_registration_path "/registration"
  @registration_path_key :registration_path
  @new_registration_path_key :new_registration_path
  @edit_registration_path_key :edit_registration_path

  @default_email_regexp ~R/^[^@\s]+@[^@\s]+$/
  @default_case_insensitive_keys ~W[email]a
  @default_strip_whitespace_keys ~W[email]a
  @default_registration_disabled? false
  @default_email_index_name nil

  @moduledoc """
  This plugin allows the user to register and edit their account.

  Change *your_app*/lib/*your_app*/user.ex to add two functions: `create_registration_changeset` and `update_registration_changeset`.

  Example:

      defmodule YourApp.User do
        require YourApp.Haytni

        @derive {Inspect, except: [:password]}
        schema "users" do
          YourApp.Haytni.fields()

          # ...
        end

        # ...

        # called when a user try to register himself
        def create_registration_changeset(%__MODULE__{} = struct, params) do
          struct
          |> cast(params, ~W[email password]a) # add any field you'll may need (but only fields that user is allowed to define!)
          |> YourApp.Haytni.validate_password()
          # add any custom validation here
          |> YourApp.Haytni.validate_create_registration()
        end

        # called when a user try to edit its own account (logic is completely different)
        def update_registration_changeset(%__MODULE__{} = struct, params) do
          struct
          |> cast(params, ~W[]a) # add any field in the list you'll may need (but only fields that user is allowed to redefine!)
          # add any custom validation here
          |> YourApp.Haytni.validate_update_registration()
        end

        # ...
      end

  Fields: none

  Configuration:

    * `email_regexp` (default: `#{inspect(@default_email_regexp)}`): the `Regex` that an email at registration or profile edition needs to match
    * `case_insensitive_keys` (default: `#{inspect(@default_case_insensitive_keys)}`): list of fields to automatically downcase on registration. May be unneeded depending on your
      database (eg: *citext* columns for PostgreSQL or columns with a collation suffixed by "\_ci" for MySQL). You **SHOULD NOT** include the
      password field here!
    * `strip_whitespace_keys` (default: `#{inspect(@default_strip_whitespace_keys)}`): list of fields to automatically strip from whitespaces. You **SHOULD NEITHER** include the
      password field here, to exclude any involuntary mistake, you should instead consider using a custom validation.
    * `email_index_name` (default: `#{inspect(@default_email_index_name)}`, translated to `<source>_email_index` by `Ecto.Changeset.unique_constraint/3`): the name of the unique
      index/constraint on email field
    * `registration_disabled?` (default: `#{inspect(@default_registration_disabled?)}`): disable any new registration (existing users are still able to login, edit their profile, ...)

          stack #{inspect(__MODULE__)},
            registration_disabled?: #{inspect(@default_registration_disabled?)},
            strip_whitespace_keys: #{inspect(@default_strip_whitespace_keys)},
            case_insensitive_keys: #{inspect(@default_case_insensitive_keys)},
            email_regexp: #{inspect(@default_email_regexp)},
            email_index_name: #{inspect(@default_email_index_name)}

  Routes:

    * `haytni_<scope>_registration_path` (actions: new/create, edit/update): paths used by the generated routes for this plugin can be customized on YourAppWeb.Haytni.routes/1 call in your router by the following options:
      - #{@registration_path_key} (default: `#{inspect(@default_registration_path)}`): the base/default path for all the actions
      - #{@new_registration_path_key} (default: `registration_path <> "/new"`): define this option to define a specific path for the *new* action (sign up/account creation)
      - #{@edit_registration_path_key} (default: `registration_path <> "/edit"`): same for *edit* action (profile edition)
  """

  require Haytni.Gettext
  import Haytni.Helpers

  defmodule Config do
    defstruct registration_disabled?: false,
      strip_whitespace_keys: ~W[email]a,
      case_insensitive_keys: ~W[email]a,
      email_regexp: ~R/^[^@\s]+@[^@\s]+$/,
      email_index_name: nil

    @typep index_name :: atom | String.t | nil

    @type t :: %__MODULE__{
      email_regexp: Regex.t,
      email_index_name: index_name,
      strip_whitespace_keys: [atom],
      case_insensitive_keys: [atom],
    }
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %Haytni.RegisterablePlugin.Config{}
    |> Haytni.Helpers.merge_config(options)
  end

  @impl Haytni.Plugin
  def files_to_install(_base_path, web_path, scope, _timestamp) do
    [
      {:eex, "views/registration_view.ex", Path.join([web_path, "views", "haytni", scope, "registration_view.ex"])},
      {:eex, "templates/registration/new.html.heex", Path.join([web_path, "templates", "haytni", scope, "registration", "new.html.heex"])},
      {:eex, "templates/registration/edit.html.heex", Path.join([web_path, "templates", "haytni", scope, "registration", "edit.html.heex"])},
    ]
  end

  @impl Haytni.Plugin
  def routes(prefix_name, options) do
    registration_prefix_name = :"#{prefix_name}_registration"
    registration_path = Keyword.get(options, @registration_path_key, @default_registration_path)
    new_registration_path = Keyword.get(options, @new_registration_path_key, registration_path <> "/new")
    edit_registration_path = Keyword.get(options, @edit_registration_path_key, registration_path <> "/edit")
    #cancel_registration_path = Keyword.get(options, :cancel_registration_path)
    quote bind_quoted: [registration_prefix_name: registration_prefix_name, registration_path: registration_path, new_registration_path: new_registration_path, edit_registration_path: edit_registration_path] do
      #resources "/registration", HaytniWeb.Registerable.RegistrationController, singleton: true, only: ~W[new create edit update]a, as: registration_prefix_name
      get new_registration_path, HaytniWeb.Registerable.RegistrationController, :new, as: registration_prefix_name
      post registration_path, HaytniWeb.Registerable.RegistrationController, :create, as: registration_prefix_name
      get edit_registration_path, HaytniWeb.Registerable.RegistrationController, :edit, as: registration_prefix_name
      put registration_path, HaytniWeb.Registerable.RegistrationController, :update, as: registration_prefix_name
      patch registration_path, HaytniWeb.Registerable.RegistrationController, :update, as: registration_prefix_name
      #if cancel_registration_path do
        #delete cancel_registration_path, HaytniWeb.Registerable.RegistrationController, :delete, as: registration_prefix_name
      #end
    end
  end

  defp validate_email(changeset = %Ecto.Changeset{}, module, config = %Config{}) do
    changeset
    |> Ecto.Changeset.validate_required([:email])
    |> Ecto.Changeset.unsafe_validate_unique(:email, module.repo())
    |> Ecto.Changeset.validate_format(:email, config.email_regexp)
    |> Ecto.Changeset.unique_constraint(:email, name: config.email_index_name)
  end

  defp base_validate_password(changeset = %Ecto.Changeset{}) do
    changeset
    |> Ecto.Changeset.validate_required([:password])
    |> Ecto.Changeset.validate_confirmation(:password, required: true)
  end

  @doc ~S"""
  The translated string to display when user's current password is incorrect
  """
  @spec invalid_current_password_message() :: String.t
  def invalid_current_password_message do
    Haytni.Gettext.dgettext("haytni", "is invalid")
  end

  @doc ~S"""
  The translated string to display when email hasn't changed
  """
  @spec has_not_changed_message() :: String.t
  def has_not_changed_message do
    Haytni.Gettext.dgettext("haytni", "has not changed")
  end

  defp validate_current_password(changeset = %Ecto.Changeset{}, password, module) do
    config = module.fetch_config(Haytni.AuthenticablePlugin)
    if Haytni.AuthenticablePlugin.valid_password?(changeset.data, password, config) do
      changeset
    else
      Ecto.Changeset.add_error(changeset, :current_password, invalid_current_password_message())
    end
  end

  @impl Haytni.Plugin
  def validate_create_registration(changeset = %Ecto.Changeset{}, module, config) do
    changeset
    # <normalization>
    |> strip_whitespace_changes(config)
    |> case_insensitive_changes(config)
    # </normalization>
    |> Ecto.Changeset.validate_confirmation(:email, required: true)
    |> validate_email(module, config)
    |> base_validate_password()
  end

  @spec validate_change(changeset :: Ecto.Changeset.t, field :: atom) :: Ecto.Changeset.t
  defp validate_change(changeset = %Ecto.Changeset{}, field)
    when is_atom(field)
  do
if true do
    # NOTE: we can't distinguish an empty value to an unchanged value since both generates no changes
    # to "leverage" it, we first check the field doesn't already have an error associated to it
    if is_nil(changeset.errors[field]) and :error == Ecto.Changeset.fetch_change(changeset, field) do
      Ecto.Changeset.add_error(changeset, field, has_not_changed_message())
    else
      changeset
    end
else
    changeset
    |> Ecto.Changeset.fetch_change(field)
    |> case do
      {:ok, _value} ->
        changeset
      :error ->
        Ecto.Changeset.add_error(changeset, field, has_not_changed_message())
    end
end
  end

  @spec email_changeset(module :: module, config :: Config.t, user :: Haytni.user, attrs :: Haytni.params) :: Ecto.Changeset.t
  defp email_changeset(module, config = %Config{}, user = %_{}, attrs = %{}) do
    user
    |> Ecto.Changeset.cast(attrs, [:email])
    |> validate_email(module, config)
    |> validate_change(:email)
  end

  @doc ~S"""
  Returns an `%Ecto.Changeset{}` to modify its email address.
  """
  @spec change_email(module :: module, config :: Config.t, user :: Haytni.user, attrs :: Haytni.params) :: Ecto.Changeset.t
  def change_email(module, config = %Config{}, user = %_{}, attrs \\ %{}) do
    email_changeset(module, config, user, attrs)
  end

  @doc ~S"""
  Updates *user*'s email address if *current_password* matches *user*'s actual password. 
  """
  @spec update_email(module :: module, config :: Config.t, user :: Haytni.user, current_password :: String.t, attrs :: Haytni.params) :: Haytni.repo_nobang_operation(Haytni.user)
  def update_email(module, config = %Config{}, user = %_{}, current_password, attrs = %{}) do
    module
    |> email_changeset(config, user, attrs)
    |> validate_current_password(current_password, module)
    |> Ecto.Changeset.apply_action(:update)
    |> case do
      {:ok, changeset_user} ->
        module
        |> Haytni.email_changed(user, changeset_user.email)
        |> multi_to_regular_result(:user)
      error = {:error, %Ecto.Changeset{}} ->
        error
    end
  end

  @spec password_changeset(module :: module, user :: Haytni.user, attrs :: Haytni.params) :: Ecto.Changeset.t
  defp password_changeset(module, user = %_{}, attrs = %{}) do
    changeset =
      user
      |> Ecto.Changeset.cast(attrs, [:password])
      |> base_validate_password()
    Haytni.validate_password(module, changeset)
  end

  @doc ~S"""
  Returns an `%Ecto.Changeset{}` to modify its password.
  """
  @spec change_password(module :: module, user :: Haytni.user, attrs :: Haytni.params) :: Ecto.Changeset.t
  def change_password(module, user = %_{}, attrs \\ %{}) do
    password_changeset(module, user, attrs)
  end

  defp maybe_hash_password(changeset = %Ecto.Changeset{valid?: true, changes: %{password: new_password}}, module) do
    config = module.fetch_config(Haytni.AuthenticablePlugin)
    changeset
    |> Ecto.Changeset.put_change(:encrypted_password, Haytni.AuthenticablePlugin.hash_password(new_password, config))
    |> Ecto.Changeset.delete_change(:password)
  end

  defp maybe_hash_password(changeset = %Ecto.Changeset{}, _module), do: changeset

  @doc ~S"""
  Updates *user*'s password if:

    + *current_password* matches *user*'s actual password
    + the new password meets the requirements against the active plugins implementing the `c:Haytni.Plugin.validate_password/3` callback

  When the password is changed, the tokens associated to *user* are also deleted.
  """
  @spec update_password(module :: module, user :: Haytni.user, current_password :: String.t, attrs :: Haytni.params) :: Haytni.repo_nobang_operation(Haytni.user)
  def update_password(module, user = %_{}, current_password, attrs = %{}) do
    changeset =
      module
      |> password_changeset(user, attrs)
      |> validate_current_password(current_password, module)
      |> maybe_hash_password(module)

    changeset
    |> Ecto.Changeset.apply_action(:update)
    |> case do
      {:ok, _changeset_user} ->
        Ecto.Multi.new()
        |> Ecto.Multi.update(:user, changeset)
        |> Haytni.Token.delete_tokens_in_multi(:tokens, user, :all)
        |> module.repo().transaction()
        |> multi_to_regular_result(:user)
      error = {:error, %Ecto.Changeset{}} ->
        error
    end
  end

if false do
  @doc ~S"""
  Apply a function/1 to the given fields of a changeset
  """
end
  @spec apply_to_fields(fields :: [atom], changeset :: Ecto.Changeset.t, fun :: (any -> any)) :: Ecto.Changeset.t
  defp apply_to_fields(fields, changeset = %Ecto.Changeset{}, fun) do
    fields
    |> Enum.reduce(changeset, &Ecto.Changeset.update_change(&2, &1, fun))
  end

  @doc ~S"""
  Trim values of a changeset to keys configured as *strip_whitespace_keys*
  """
  @spec strip_whitespace_changes(changeset :: Ecto.Changeset.t, config :: Config.t) :: Ecto.Changeset.t
  def strip_whitespace_changes(changeset = %Ecto.Changeset{}, config) do
    config.strip_whitespace_keys
    |> apply_to_fields(changeset, &String.trim/1)
  end

  @doc ~S"""
  Downcase values of a changeset to keys configured as *case_insensitive_keys*
  """
  @spec case_insensitive_changes(changeset :: Ecto.Changeset.t, config :: Config.t) :: Ecto.Changeset.t
  def case_insensitive_changes(changeset = %Ecto.Changeset{}, config) do
    config.case_insensitive_keys
    |> apply_to_fields(changeset, &String.downcase/1)
  end
end
