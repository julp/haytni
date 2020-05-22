defmodule <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "LockableChanges"]) %> do
  use Ecto.Migration

  def change do
    create_if_not_exists table(<%= inspect table %>) do
      # NOP
    end

    alter table(<%= inspect table %>) do
      add :locked_at, :utc_datetime, default: nil
      add :failed_attempts, :integer, default: 0, null: false
      add :unlock_token, :string, default: nil
    end

    create index(<%= inspect table %>, ~W[unlock_token]a, unique: true)
  end
end
