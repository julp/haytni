defmodule <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "AuthenticableCreation"]) %> do
  use Ecto.Migration

  def change(table \\ <%= inspect table %>) do
    create_if_not_exists table(table) do
      # NOP
    end

    alter table(table) do
      add :email, :string, null: false
      add :encrypted_password, :string, null: false
    end

    create index(table, ~W[email]a, unique: true)
  end
end
