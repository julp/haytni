defmodule <%= [:Haytni, "Migrations", camelized_scope, "EncryptedEmailChanges"] |> Module.concat() |> inspect() %> do
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

    create unique_index(table, [@column])

    _ = """
    Ecto.Migration.flush()

    query = from(
      u in module.schema(),
      set: [
        {@column, fragment("encode(sha256(?::TEXT::BYTEA), 'hex')", u.email)},
      ]
    )
    module.repo().update_all(query, [])
    """

    execute("UPDATE #{table} SET #{@column} = encode(sha256(email::TEXT::BYTEA), 'hex');")
    #execute("CREATE UNIQUE INDEX ON #{table}(#{@column});")
    execute("ALTER TABLE #{table} ALTER COLUMN #{@column} DROP NOT NULL;")
  end
end
