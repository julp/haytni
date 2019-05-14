defmodule Haytni.Connection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "connections" do
    field :ip, EctoNetwork.INET
    timestamps(updated_at: false)

    belongs_to :user, Haytni.schema()
  end

  @attributes ~W[ip]a
  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, @attributes)
    |> validate_required(@attributes)
  end
end
