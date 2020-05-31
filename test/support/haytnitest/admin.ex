defmodule HaytniTest.Admin do
  use Ecto.Schema
  require HaytniTestWeb.HaytniAdmin
  import Ecto.Changeset

  schema "admins" do
    HaytniTestWeb.HaytniAdmin.fields()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [])
  end

  @attributes ~W[email password]a
  def create_registration_changeset(struct = %__MODULE__{}, params) do
    struct
    |> cast(params, @attributes)
    |> validate_required(@attributes)
    |> HaytniTestWeb.HaytniAdmin.validate_password()
    |> HaytniTestWeb.HaytniAdmin.validate_create_registration()
  end

  def update_registration_changeset(struct = %__MODULE__{}, params) do
    struct
    |> cast(params, ~W[email password current_password]a)
    |> HaytniTestWeb.HaytniAdmin.validate_update_registration()
  end
end
