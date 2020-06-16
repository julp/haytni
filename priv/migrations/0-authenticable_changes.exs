defmodule <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "AuthenticableCreation"]) %> do
  use Ecto.Migration

  def change(table \\ <%= inspect table %>) do
    create_if_not_exists table(table) do
      # NOP
    end

    cistring = Haytni.Helpers.case_insensitive_string_type()

    alter table(table) do
      add :email, cistring, null: false
      add :encrypted_password, :string, null: false
    end

    create index(table, ~W[email]a, unique: true)
  end
end
