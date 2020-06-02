defmodule HaytniTest.User do
  use Ecto.Schema
  require HaytniTestWeb.Haytni
  import Ecto.Changeset

  @derive {Inspect, except: [:password]}
  schema "users" do
    HaytniTestWeb.Haytni.fields()
    field :dummy, :boolean, default: false
    field :lastname, :string
    field :firstname, :string
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
    |> HaytniTestWeb.Haytni.validate_password()
    |> HaytniTestWeb.Haytni.validate_create_registration()
  end

  def update_registration_changeset(struct = %__MODULE__{}, params) do
    struct
    |> cast(params, ~W[email password current_password]a)
    |> HaytniTestWeb.Haytni.validate_update_registration()
  end
end
