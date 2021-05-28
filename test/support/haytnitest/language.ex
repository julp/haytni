defmodule HaytniTest.Language do
  use Ecto.Schema

  @type t :: %__MODULE__{}

  schema "languages" do
    field :name, :string

    #has_many :users, HaytniTest.User
  end
end
