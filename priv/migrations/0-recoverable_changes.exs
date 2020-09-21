defmodule <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "RecoverableChanges"]) %> do
  use Ecto.Migration

  def change(table \\ <%= inspect table %>) do
    create_if_not_exists table(table) do
      # NOP
    end

    alter table(table) do
      add :reset_password_token, :string, default: nil
      add :reset_password_sent_at, :utc_datetime, default: nil
    end

    create unique_index(table, ~W[reset_password_token]a)
  end
end
