defmodule <%= [:Haytni, "Migrations", camelized_scope, "EncryptedEmailChanges"] |> Module.concat() |> inspect() %> do
  use Ecto.Migration

  @column :encrypted_email
  def change(users_table \\ <%= inspect(table) %>) do
    cistring = Haytni.Migration.case_insensitive_string_type()

    create_if_not_exists table(users_table) do
      # NOP
    end

    alter table(users_table) do
      add @column, cistring, null: true, default: nil
    end

    create unique_index(users_table, [@column])

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

    execute("UPDATE #{users_table} SET #{@column} = encode(sha256(email::TEXT::BYTEA), 'hex');")
    #execute("CREATE UNIQUE INDEX ON #{users_table}(#{@column});")
    execute("ALTER TABLE #{users_table} ALTER COLUMN #{@column} DROP NOT NULL;")
  end
end
