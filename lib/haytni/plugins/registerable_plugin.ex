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
          |> cast(params, ~W[email password current_password]a) # add any field you'll may need (but only fields that user is allowed to redefine!)
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

          stack Haytni.RegisterablePlugin,
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
      {:eex, "templates/registration/new.html.eex", Path.join([web_path, "templates", "haytni", scope, "registration", "new.html.eex"])},
      {:eex, "templates/registration/edit.html.eex", Path.join([web_path, "templates", "haytni", scope, "registration", "edit.html.eex"])},
    ]
  end

  @impl Haytni.Plugin
  def fields(_module) do
    quote do
      field :current_password, :string, virtual: true
    end
  end

  @impl Haytni.Plugin
  def routes(prefix_name, options) do
    prefix_name = :"#{prefix_name}_registration"
    registration_path = Keyword.get(options, @registration_path_key, @default_registration_path)
    new_registration_path = Keyword.get(options, @new_registration_path_key, registration_path <> "/new")
    edit_registration_path = Keyword.get(options, @edit_registration_path_key, registration_path <> "/edit")
    #cancel_registration_path = Keyword.get(options, :cancel_registration_path)
    quote bind_quoted: [prefix_name: prefix_name, registration_path: registration_path, new_registration_path: new_registration_path, edit_registration_path: edit_registration_path] do
      #resources "/registration", HaytniWeb.Registerable.RegistrationController, singleton: true, only: ~W[new create edit update]a, as: prefix_name
      get new_registration_path, HaytniWeb.Registerable.RegistrationController, :new, as: prefix_name
      post registration_path, HaytniWeb.Registerable.RegistrationController, :create, as: prefix_name
      get edit_registration_path, HaytniWeb.Registerable.RegistrationController, :edit, as: prefix_name
      put registration_path, HaytniWeb.Registerable.RegistrationController, :update, as: prefix_name
      patch registration_path, HaytniWeb.Registerable.RegistrationController, :update, as: prefix_name
      #if cancel_registration_path do
        #delete cancel_registration_path, HaytniWeb.Registerable.RegistrationController, :delete, as: prefix_name
      #end
    end
  end

  defp validate_both_registration(changeset = %Ecto.Changeset{}, config) do
    changeset
    # "normalization"
    |> strip_whitespace_changes(config)
    |> case_insensitive_changes(config)
    # email
    #|> Ecto.Changeset.unsafe_validate_unique(:email)
    |> Ecto.Changeset.validate_format(:email, config.email_regexp)
    |> Ecto.Changeset.unique_constraint(:email, name: config.email_index_name)
  end

  defp validate_password(changeset = %Ecto.Changeset{}) do
    changeset
    |> Ecto.Changeset.validate_confirmation(:password, required: true)
  end

  @impl Haytni.Plugin
  def validate_create_registration(changeset = %Ecto.Changeset{}, config) do
    changeset
    |> Ecto.Changeset.validate_required(~W[email password]a)
    |> validate_both_registration(config)
    |> Ecto.Changeset.validate_confirmation(:email, required: true)
    |> validate_password()
  end

  defp add_validate_required_current_password(changeset = %Ecto.Changeset{}) do
    changeset
    |> Ecto.Changeset.validate_required(:current_password)
  end

  # registration edition helpers

  # current password is needed/checked if at least one of the password or email is changed
  defp handle_current_password_requirement(changeset = %Ecto.Changeset{changes: %{email: _}}), do: add_validate_required_current_password(changeset)
  defp handle_current_password_requirement(changeset = %Ecto.Changeset{changes: %{password: _}}), do: add_validate_required_current_password(changeset)
  defp handle_current_password_requirement(changeset = %Ecto.Changeset{}), do: changeset

  defp handle_password(changeset = %Ecto.Changeset{changes: %{password: _}}, _config) do
    changeset
    |> validate_password()
  end
  defp handle_password(changeset = %Ecto.Changeset{}, _config), do: changeset

  @impl Haytni.Plugin
  def validate_update_registration(changeset = %Ecto.Changeset{}, config) do
    changeset
    # NOTE: in the opposite of validate_create_registration, password is NOT required here
    |> Ecto.Changeset.validate_required(~W[email]a)
    |> validate_both_registration(config)
    |> handle_current_password_requirement()
    |> handle_password(config)
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
