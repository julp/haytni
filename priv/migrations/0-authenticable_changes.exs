defmodule <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "AuthenticableCreation"]) %> do
  use Ecto.Migration

  def change(table \\ <%= inspect table %>) do
    create_if_not_exists table(table) do
      # NOP
    end

    cistring = Haytni.Migration.case_insensitive_string_type()
    alter table(table) do
      add :email, cistring, null: false
      add :encrypted_password, :string, null: false
    end

    create unique_index(table, ~W[email]a)
  end
end
