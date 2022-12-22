defmodule Haytni.EncryptedEmailPlugin do
  @default_fields_to_reset_on_delete ~W[email encrypted_password]a

  @moduledoc """
  This plugin is intended to anonymize user's data on deletion but keep the email in an hashed form to prevent abuse (deleting the account then recreate it with same address).

  Fields:

    * encrypted_email (string, non-nullable): a hash of the active user's email

  Configuration:

    * `fields_to_reset_on_delete` (default: `#{inspect(@default_fields_to_reset_on_delete)}`): the fields to reset/change on account deletion. Examples:

      + `[:email, :encrypted_password]` set `:email` and `:encrypted_password` to `nil`
      + `[email: nil, encrypted_password: "<ACCOUNT DELETED>", name: fn user -> "Account deleted #\#{user.id}" end]` set `:email` to `nil`, `encrypted_password` to `"<ACCOUNT DELERED>"` and `:name` to `"Account deleted #\#{user.id}"`.

  Routes: none
  """

  defmodule Config do
    defstruct fields_to_reset_on_delete: ~W[email encrypted_password]a

    @type t :: %__MODULE__{
      fields_to_reset_on_delete: [atom | {atom, any} | (struct -> any)],
    }
  end

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %Haytni.AuthenticablePlugin.Config{}
    |> Haytni.Helpers.merge_config(options)
  end

  @impl Haytni.Plugin
  def files_to_install(_base_path, web_path, scope, timestamp) do
    [
      # migration
      {:eex, "migrations/0-encrypted_email_changes.exs", Path.join([web_path, "..", "..", "priv", "repo", "migrations", "#{timestamp}_haytni_encrypted_email_#{scope}_changes.exs"])},
    ]
  end

  @impl Haytni.Plugin
  def fields(_module) do
    quote do
      field :encrypted_email, :string # UNIQUE
    end
  end

  defp put_hash(changeset) do
    if changeset.valid? do
      changeset
      |> Ecto.Changeset.put_change(:encrypted_email, :crypto.hash(:sha256, changeset.changes.email) |> Base.encode16())
    else
      changeset
    end
  end

  @impl Haytni.Plugin
  def validate_create_registration(changeset, module, _config) do
    changeset
    |> Ecto.Changeset.unsafe_validate_unique(:encrypted_email, module.repo())
    |> put_hash()
  end

  @impl Haytni.Plugin
  def validate_update_registration(changeset, module, _config) do
    changeset
    |> Ecto.Changeset.unsafe_validate_unique(:encrypted_email, module.repo())
  end

  @impl Haytni.Plugin
  def on_email_change(multi, changeset, _module, _config) do
    {multi, put_hash(changeset)}
  end

  @impl Haytni.Plugin
  def on_delete_user(multi, user, _module, config) do
    pairs =
      config.fields_to_reset_on_delete
      |> Enum.map(
        fn
          f when is_atom(f) -> {f, nil}
          {f, v} when is_function(v, 1) -> {f, v.(user)}
          tuple = {_f, _v} -> tuple
        end
      )
    changeset = Ecto.Changeset.change(user, pairs)

    Ecto.Multi.update(multi, :update, changeset)
  end
end
