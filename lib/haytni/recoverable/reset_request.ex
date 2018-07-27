defmodule Haytni.Recoverable.ResetRequest do
  import Ecto.Changeset

  defstruct Haytni.RecoverablePlugin.reset_password_keys()

  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    keys = Haytni.RecoverablePlugin.reset_password_keys()
    types = keys
    |> Enum.into(%{}, fn key -> {key, :string} end)

    {struct, types}
    |> cast(params, keys)
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
