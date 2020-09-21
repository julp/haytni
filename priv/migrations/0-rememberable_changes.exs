defmodule <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "RememberableChanges"]) %> do
  use Ecto.Migration

  def change(table \\ <%= inspect table %>) do
    create_if_not_exists table(table) do
      # NOP
    end

    alter table(table) do
      add :remember_token, :string, default: nil
      add :remember_created_at, :utc_datetime, default: nil
    end

    create unique_index(table, ~W[remember_token]a)
  end
end
