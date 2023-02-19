defmodule <%= [:Haytni, "Migrations", camelized_scope, "LockableChanges"] |> Module.concat() |> inspect() %> do
  use Ecto.Migration

  def change(table \\ <%= inspect(table) %>) do
    create_if_not_exists table(<%= inspect(table) %>) do
      # NOP
    end

    alter table(table) do
      add :locked_at, :utc_datetime, default: nil
      add :failed_attempts, :integer, default: 0, null: false
    end
  end
end
