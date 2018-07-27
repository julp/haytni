defmodule Haytni.RegisterablePlugin do
  @moduledoc ~S"""
  This plugin allows the user to register and edit their registration.

  Change *your_app*/lib/*your_app*/user.ex to add two functions: `create_registration_changeset` and `update_registration_changeset`.

  Example:

      defmodule YourApp.User do
        # ...

        @attributes ~W[email password]a # add any field you'll may need
        # called when a user try to register himself
        def create_registration_changeset(%__MODULE__{} = struct, params) do
          struct
          |> cast(params, @attributes)
          |> validate_required(@attributes)
          # add any custom validation here
          |> Haytni.validate_create_registration()
        end

        # called when a user try to edit its own account (logic is completely different)
        def update_registration_changeset(%__MODULE__{} = struct, params) do
          struct
          |> cast(params, ~W[email password current_password]a)
          # /!\ email and password are not necessarily required here /!\
          # add any custom validation here
          |> Haytni.validate_update_registration()
        end

        # ...
      end

  Configuration:

    * `password_length` (default: `6..128`): define min and max password length as an Elixir Range
    * `email_regexp` (default: `~R/^[^@\s]+@[^@\s]+$/`): the Regexp that an email at registration or profile edition needs to match
    * `case_insensitive_keys` (default: `~W[email]a`): list of fields to automatically downcase on registration. May be unneeded depending on your database (eg: *citext* columns for PostgreSQL or columns with a collation suffixed by "\_ci" for MySQL)
    * `strip_whitespace_keys` (default: `~W[email]a`): list of fields to automatically strip from whitespaces
    * `email_index_name` (default: `"users_email_index"`): the name of the unique index/constraint on email field

  Routes:

    * `registration_path` (actions: new/create, edit/update, delete)
  """

  #import Plug.Conn
  import Ecto.Changeset
  #import Haytni.Gettext

  use Haytni.Plugin
  use Haytni.Config, [
    password_length: 6..128,
    strip_whitespace_keys: ~W[email]a,
    case_insensitive_keys: ~W[email]a,
    email_regexp: ~R/^[^@\s]+@[^@\s]+$/,
    email_index_name: "users_email_index",
  ]

  @impl Haytni.Plugin
  def files_to_install do
    import Mix.Tasks.Haytni.Install, only: [web_path: 0]
    [
      {:eex, "views/registration_view.ex", Path.join([web_path(), "views", "haytni", "registration_view.ex"])},
      {:eex, "templates/registration/new.html.eex", Path.join([web_path(), "templates", "haytni", "registration", "new.html.eex"])},
      {:text, "templates/registration/edit.html.eex", Path.join([web_path(), "templates", "haytni", "registration", "edit.html.eex"])}
    ]
  end

  @impl Haytni.Plugin
  def fields do
    quote do
      field :current_password, :string, virtual: true
    end
  end

  #@default_paths [registration: "/register", sign_up: "", edit: "", cancel: ""]

  @impl Haytni.Plugin
  def routes(_scope, _options) do
    #registration_path = @default_paths
    #|> Keyword.merge(Keyword.get(options, :path_names, []))
    #|> Keyword.fetch!(:registration)
    quote do
      resources "/registration", HaytniWeb.Registerable.RegistrationController, singleton: true, only: ~W[new create edit update]a
    end
  end

  defp validate_both_registration(changeset = %Ecto.Changeset{}) do
    changeset
    # "normalization"
    |> strip_whitespace_changes()
    |> case_insensitive_changes()
  end

  defp validate_email(changeset = %Ecto.Changeset{}) do
    changeset
    |> validate_format(:email, email_regexp())
    |> unique_constraint(:email, name: email_index_name())
  end

  defp validate_password(changeset = %Ecto.Changeset{}) do
    min_pwd_len..max_pwd_len = password_length()
    changeset
    |> validate_confirmation(:password, required: true)
    |> validate_length(:password, min: min_pwd_len, max: max_pwd_len)
  end

  @impl Haytni.Plugin
  def validate_create_registration(changeset = %Ecto.Changeset{}) do
    changeset
    |> validate_both_registration()
    |> validate_email()
    |> validate_confirmation(:email, required: true)
    |> validate_password()
  end

  defp add_validate_required_current_password(changeset = %Ecto.Changeset{}) do
    changeset
    |> validate_required(:current_password)
  end

  # registration edition helpers
  defp handle_current_password_requirement(changeset = %Ecto.Changeset{changes: %{email: _}}), do: add_validate_required_current_password(changeset)
  defp handle_current_password_requirement(changeset = %Ecto.Changeset{changes: %{password: _}}), do: add_validate_required_current_password(changeset)
  defp handle_current_password_requirement(changeset = %Ecto.Changeset{}), do: changeset

  defp handle_email(changeset = %Ecto.Changeset{changes: %{email: _}}) do
    changeset
    |> validate_email()
  end
  defp handle_email(changeset = %Ecto.Changeset{}), do: changeset

  defp handle_password(changeset = %Ecto.Changeset{changes: %{password: _}}) do
    changeset
    |> validate_password()
  end
  defp handle_password(changeset = %Ecto.Changeset{}), do: changeset

  @impl Haytni.Plugin
  def validate_update_registration(changeset = %Ecto.Changeset{}) do
    changeset
    |> validate_both_registration()
    |> handle_current_password_requirement()
    |> handle_email()
    |> handle_password()
  end

  # Apply a function/1 to the given fields of a changeset
  @spec apply_to_fields(fields :: [atom], changeset :: Ecto.Changeset.t, fun :: (any -> any)) :: Ecto.Changeset.t
  defp apply_to_fields(fields, changeset = %Ecto.Changeset{}, fun) do
    fields
    #|> Enum.reduce(struct, &Map.update!(&2, &1, fun))
    |> Enum.reduce(changeset, &Ecto.Changeset.update_change(&2, &1, fun))
  end

  @doc ~S"""
  Trim values of a changeset to keys configured as *strip_whitespace_keys*
  """
  @spec strip_whitespace_changes(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  def strip_whitespace_changes(changeset = %Ecto.Changeset{}) do
    Haytni.fetch_config(:strip_whitespace_keys, strip_whitespace_keys())
    |> apply_to_fields(changeset, &String.trim/1)
  end

  @doc ~S"""
  Downcase values of a changeset to keys configured as *case_insensitive_keys*
  """
  @spec case_insensitive_changes(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  def case_insensitive_changes(changeset = %Ecto.Changeset{}) do
    Haytni.fetch_config(:case_insensitive_keys, case_insensitive_keys())
    |> apply_to_fields(changeset, &String.downcase/1)
  end
end
