defmodule Haytni.Confirmation do
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  defstruct ~W[referer]a ++ Haytni.ConfirmablePlugin.confirmation_keys()

  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    keys = Haytni.ConfirmablePlugin.confirmation_keys()
    types = keys
    |> Enum.into(%{referer: :string}, fn key -> {key, :string} end)

    {struct, types}
    |> cast(params, Map.keys(types))
    |> validate_required(keys)
  end

  def change_confirmation do
    %__MODULE__{}
    |> change_confirmation()
  end

  def change_confirmation(%__MODULE__{} = confirmation) do
    confirmation
    |> changeset()
  end

  def create_confirmation(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end
end
