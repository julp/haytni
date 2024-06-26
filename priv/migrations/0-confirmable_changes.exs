defmodule <%= [:Haytni, "Migrations", camelized_scope, "ConfirmableChanges"] |> Module.concat() |> inspect() %> do
  use Ecto.Migration

  def change(users_table \\ <%= inspect(table) %>) do
    create_if_not_exists table(users_table) do
      # NOP
    end

    alter table(users_table) do
      add :confirmed_at, :utc_datetime, default: nil
    end
  end
end
