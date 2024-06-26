defmodule <%= [:Haytni, "Migrations", camelized_scope, "AuthenticableCreation"] |> Module.concat() |> inspect() %> do
  use Ecto.Migration

  def change(users_table \\ <%= inspect(table) %>) do
    cistring = Haytni.Migration.case_insensitive_string_type()

    create_if_not_exists table(users_table) do
      # NOP
    end

    alter table(users_table) do
      add :email, cistring, null: true
      add :encrypted_password, :string, null: true

      timestamps(updated_at: false, type: :utc_datetime)
    end

    create unique_index(users_table, ~W[email]a)
  end
end
