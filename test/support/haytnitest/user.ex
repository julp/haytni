defmodule HaytniTest.User do
  use Ecto.Schema
  require HaytniTestWeb.Haytni

  @derive {Inspect, except: [:password]}
  schema "users" do
    HaytniTestWeb.Haytni.fields()

    field :dummy, :boolean, default: false
    field :lastname, :string
    field :firstname, :string
  end

  def changeset(struct, params) do
    struct
    |> Ecto.Changeset.cast(params, [])
  end

  @required ~W[email password]a
  @attributes @required ++ ~W[invitation]a
  def create_registration_changeset(struct = %__MODULE__{}, params) do
    struct
    |> Ecto.Changeset.cast(params, @attributes)
    |> Ecto.Changeset.validate_required(@required)
    |> HaytniTestWeb.Haytni.validate_password()
    |> HaytniTestWeb.Haytni.validate_create_registration()
  end

  def update_registration_changeset(struct = %__MODULE__{}, params) do
    struct
    |> Ecto.Changeset.cast(params, ~W[dummy firstname lastname]a)
    |> Ecto.Changeset.validate_required(~W[firstname lastname]a)
    |> HaytniTestWeb.Haytni.validate_update_registration()
  end
end
