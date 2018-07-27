defmodule Haytni.Recoverable.PasswordChange do
  import Ecto.Changeset

  defstruct ~W[reset_password_token password]a

  @types %{reset_password_token: :string, password: :string}
  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    {struct, @types}
    |> cast(params, Map.keys(@types))
    |> validate_required(Map.keys(@types))
    |> validate_confirmation(:password, required: true)
  end

  def change_password(%__MODULE__{} = request) do
    request
    |> changeset()
  end

  def change_password(params = %{}) do
    %__MODULE__{}
    |> changeset(params)
  end

  def create_password(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end
end
