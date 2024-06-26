defmodule <%= [:Haytni, "Migrations", camelized_scope, "LockableChanges"] |> Module.concat() |> inspect() %> do
  use Ecto.Migration

  def change(users_table \\ <%= inspect(table) %>) do
    create_if_not_exists table(users_table) do
      # NOP
    end

    alter table(users_table) do
      add :locked_at, :utc_datetime, default: nil
      add :failed_attempts, :integer, default: 0, null: false
    end
  end
end
