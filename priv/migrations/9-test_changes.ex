defmodule <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "TestChanges"]) %> do
  use Ecto.Migration

  def change do
    create_if_not_exists table(<%= inspect table %>) do
      # NOP
    end

    alter table(<%= inspect table %>) do
      add :dummy, :boolean, null: false, default: false

      add :lastname, :string, null: true, default: nil
      add :firstname, :string, null: true, default: nil
    end

    admin_table = HaytniTest.Admin.__schema__(:source)
    <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "AuthenticableCreation"]) %>.change(admin_table)
    <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "TrackableChanges"]) %>.change(admin_table, :admin)
  end
end
