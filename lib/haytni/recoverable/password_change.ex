defmodule Haytni.Recoverable.PasswordChange do
  import Ecto.Changeset

  @type t :: %__MODULE__{
    password: String.t,
    reset_password_token: String.t,
  }

  defstruct ~W[reset_password_token password]a

  @types %{reset_password_token: :string, password: :string}
  @keys Map.keys(@types)
  def changeset(module, struct = %__MODULE__{}, params \\ %{}) do
    changeset = {struct, @types}
    |> cast(params, @keys)
    |> validate_required(@keys)
    |> validate_confirmation(:password, required: true)

    Haytni.validate_password(module, changeset)
  end

  def change_password(module, params = %{}) do
    changeset(module, %__MODULE__{}, params)
  end
end
