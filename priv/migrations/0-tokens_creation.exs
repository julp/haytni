defmodule <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "TokensCreation"]) %> do
  use Ecto.Migration

  def change(users_table \\ <%= inspect table %>, _scope \\ <%= inspect to_string(scope) %>) do
    cistring = Haytni.Migration.case_insensitive_string_type()

    tokens_table = "#{users_table}_tokens"
    create table(tokens_table) do
      add :token, :binary, null: false
      add :user_id, references(users_table, on_delete: :delete_all, on_update: :update_all), null: false # TODO: :user_id vs "#{scope}_id"
      add :context, :string, null: false # TODO
      add :sent_to, cistring # TODO utilisé pour la confirmation d'email
      timestamps(updated_at: false, type: :utc_datetime)
    end

    create index(tokens_table, ~W[user_id]a)
    create unique_index(tokens_table, ~W[token context]a)
  end
end
