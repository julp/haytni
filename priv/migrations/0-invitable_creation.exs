defmodule <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "InvitableCreation"]) %> do
  use Ecto.Migration

  def change(users_table \\ <%= inspect table %>, _scope \\ <%= inspect to_string(scope) %>) do
    cistring = Haytni.Migration.case_insensitive_string_type()

    invitations_table = "#{users_table}_invitations"
    create table(invitations_table) do
      add :code, :string, null: false
      add :sent_by, references(users_table), null: false, on_delete: :delete_all, on_update: :update_all
      add :sent_to, cistring, null: false
      add :sent_at, :utc_datetime, null: false
      add :accepted_by, references(users_table), on_delete: :delete_all, on_update: :update_all, default: nil
      add :accepted_at, :utc_datetime, default: nil
    end

    create index(invitations_table, ~W[sent_by]a)
    create index(invitations_table, ~W[code]a, unique: true)
    create index(invitations_table, ~W[sent_to]a, unique: true)
  end
end
