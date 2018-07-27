defmodule Haytni.Migrations.AuthenticableCreation do
  use Ecto.Migration

  def change do
    create_if_not_exists table(<%= inspect table %>) do
      # NOP
    end

    alter table(<%= inspect table %>) do
      add :email, :string, null: false
      add :encrypted_password, :string, null: false
    end

    create index(<%= inspect table %>, ~W[email]a, unique: true)
  end
end
