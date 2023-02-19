defmodule <%= [:Haytni, "Migrations", camelized_scope, "TestChanges"] |> Module.concat() |> inspect() %> do
  use Ecto.Migration

  def change(table \\ <%= inspect(table) %>) do
    create_if_not_exists table(table) do
      # NOP
    end

    languages_table = HaytniTest.Language.__schema__(:source)
    create table(languages_table) do
      add :name, :string
    end

    alter table(table) do
      add :dummy, :boolean, null: false, default: false

      add :lastname, :string, null: true, default: nil
      add :firstname, :string, null: true, default: nil

      add :language_id, references(languages_table, on_delete: :delete_all, on_update: :update_all)
    end

    create unique_index(languages_table, ~W[name]a)

    admin_table = HaytniTest.Admin.__schema__(:source)
    <%= [:Haytni, "Migrations", camelized_scope, "AuthenticableCreation"] |> Module.concat() |> inspect() %>.change(admin_table)
    <%= [:Haytni, "Migrations", camelized_scope, "TrackableChanges"] |> Module.concat() |> inspect() %>.change(admin_table, :admin)
  end
end
