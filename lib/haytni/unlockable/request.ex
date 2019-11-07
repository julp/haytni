defmodule Haytni.Unlockable.Request do
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  defstruct ~W[referer]a ++ Haytni.LockablePlugin.unlock_keys()

  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    keys = Haytni.LockablePlugin.unlock_keys()
    types = keys
    |> Enum.into(%{referer: :string}, fn key -> {key, :string} end)

    {struct, types}
    |> cast(params, Map.keys(types))
    |> validate_required(keys)
  end

  def change_request do
    %__MODULE__{}
    |> change_request()
  end

  def change_request(%__MODULE__{} = request) do
    request
    |> changeset()
  end

  def create_request(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end
end
