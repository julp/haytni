defmodule HaytniTest.User do
  use Ecto.Schema
  require Haytni
  import Ecto.Changeset

  schema "users" do
    Haytni.fields()
    field :dummy, :boolean, default: false
  end

  @attributes ~W[email password]a
  def create_registration_changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, @attributes)
    |> validate_required(@attributes)
    |> Haytni.validate_create_registration()
  end

  def update_registration_changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, ~W[email password current_password]a)
    |> Haytni.validate_update_registration()
  end
end
