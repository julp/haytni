defmodule <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "ConfirmableChanges"]) %> do
  use Ecto.Migration

  def change(table \\ <%= inspect table %>) do
    create_if_not_exists table(table) do
      # NOP
    end

    cistring = Haytni.Helpers.case_insensitive_string_type()

    alter table(table) do
      add :confirmed_at, :utc_datetime, default: nil
      add :unconfirmed_email, cistring, default: nil
      add :confirmation_token, :string, default: nil
      add :confirmation_sent_at, :utc_datetime, null: false
    end

    create index(table, ~W[confirmation_token]a, unique: true)
  end
end
