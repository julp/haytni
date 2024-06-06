defmodule Haytni.AnonymizationPlugin do
  @default_fields_to_reset_on_delete ~W[email encrypted_password]a

  @moduledoc """
  This plugin is intended to anonymize user's data on deletion.

  Fields: none

  Configuration:

    * `fields_to_reset_on_delete` (default: `#{inspect(@default_fields_to_reset_on_delete)}`): the fields to reset/change on account deletion. Examples:

      + `[:email, :encrypted_password]` set `:email` and `:encrypted_password` to `nil`
      + `[email: nil, encrypted_password: "<ACCOUNT DELETED>", name: fn user -> "Account deleted #\#{user.id}" end]` set `:email` to `nil`, `encrypted_password` to `"<ACCOUNT DELETED>"` and `:name` to `"Account deleted #\#{user.id}"`.

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
    %Haytni.AnonymizationPlugin.Config{}
    |> Haytni.Helpers.merge_config(options)
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
