defmodule HaytniTest.Admin do
  use Ecto.Schema
  require HaytniTestWeb.Haytni2
  import Ecto.Changeset

  schema "admins" do
    HaytniTestWeb.Haytni2.fields()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [])
  end

  @attributes ~W[email password]a
  def create_registration_changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, @attributes)
    |> validate_required(@attributes)
    |> HaytniTestWeb.Haytni2.validate_password()
    |> HaytniTestWeb.Haytni2.validate_create_registration()
  end

  def update_registration_changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, ~W[email password current_password]a)
    |> HaytniTestWeb.Haytni2.validate_update_registration()
  end
end
