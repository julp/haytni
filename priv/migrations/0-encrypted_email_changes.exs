defmodule <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "EncryptedEmailChanges"]) %> do
  use Ecto.Migration

  @column :encrypted_email
  def change(table \\ <%= inspect(table) %>) do
    cistring = Haytni.Migration.case_insensitive_string_type()

    create_if_not_exists table(table) do
      # NOP
    end

    alter table(table) do
      add @column, cistring, null: true, default: nil
    end

    """
    UPDATE #{table} SET #{@column} = encode(sha256(email), 'hex');
    CREATE INDEX ON #{table}(#{@column});
    ALTER TABLE #{table} ALTER COLUMN #{@column} DROP NOT NULL;
    """
    |> execute()
  end
end
