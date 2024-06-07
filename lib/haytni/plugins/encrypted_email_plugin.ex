defmodule Haytni.EncryptedEmailPlugin do
  @moduledoc """
  This plugin is intended to keep the email in an hashed form to prevent abuse (deleting the account then recreate it with same address).

  Fields:

    * encrypted_email (string, non-nullable): a hash of the active user's email

  Configuration: none

  Routes: none
  """

  use Haytni.Plugin

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
      field :encrypted_email, :string, load_in_query: false # UNIQUE
    end
  end

  def hash_email(email)
    when is_binary(email)
  do
    :crypto.hash(:sha256, email)
    |> Base.encode16()
  end

  defp put_hash(changeset) do
    if changeset.valid? do
      changeset
      |> Ecto.Changeset.put_change(:encrypted_email, hash_email(changeset.changes.email))
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
end
