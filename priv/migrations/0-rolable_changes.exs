defmodule <%= [:Haytni, "Migrations", camelized_scope, "RolableChanges"] |> Module.concat() |> inspect() %> do
  use Ecto.Migration

  def change(users_table \\ <%= inspect(table) %>, _scope \\ <%= scope |> to_string() |> inspect() %>) do
    roles_table = "#{users_table}_roles"
    users_roles_tables = "#{users_table}_roles__assoc"
    cistring = Haytni.Migration.case_insensitive_string_type()

    create table(roles_table) do
      add :name, cistring, null: false
    end

    create unique_index(roles_table, ~W[name]a)


    fk = :user_id # :"#{scope}_id" ?
    create table(users_roles_tables) do
      add fk, references(users_table, on_delete: :delete_all, on_update: :update_all), primary_key: true, null: false
      add :role_id, references(roles_table, on_delete: :delete_all, on_update: :update_all), primary_key: true, null: false
    end
  end
end
