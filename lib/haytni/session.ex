defmodule Haytni.Session do
  import Ecto.Changeset

  defstruct Haytni.AuthenticablePlugin.authentication_keys() ++ (if Haytni.RememberablePlugin.enabled?, do: ~W[remember]a, else: []) ++ ~W[password]a

  defp add_authentication_keys(map) do
    Haytni.AuthenticablePlugin.authentication_keys()
    |> Enum.into(map, fn key -> {key, :string} end)
  end

  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    types = %{password: :string}
    |> add_authentication_keys()

    {struct, types}
    |> cast(params, Map.keys(types))
    |> validate_required(Map.keys(types))
  end

  def change_session do
    %__MODULE__{}
    |> change_session()
  end

  def change_session(%__MODULE__{} = session) do
    session
    |> changeset()
  end

  def create_session(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end
end
