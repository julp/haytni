defmodule <%= [:Haytni, "Migrations", camelized_scope, "InvitableCreation"] |> Module.concat() |> inspect() %> do
  use Ecto.Migration

  def change(users_table \\ <%= inspect(table) %>, _scope \\ <%= scope |> to_string() |> inspect() %>) do
    cistring = Haytni.Migration.case_insensitive_string_type()

    invitations_table = "#{users_table}_invitations"
    create table(invitations_table) do
      add :code, :string, null: false
      add :sent_by, references(users_table, on_delete: :delete_all, on_update: :update_all), null: false
      add :sent_to, cistring, null: false
      add :sent_at, :utc_datetime, null: false
      add :accepted_by, references(users_table, on_delete: :delete_all, on_update: :update_all), default: nil
      add :accepted_at, :utc_datetime, default: nil
    end

    create index(invitations_table, ~W[sent_by]a)
    create unique_index(invitations_table, ~W[code]a)
    create unique_index(invitations_table, ~W[sent_to]a)
  end
end
