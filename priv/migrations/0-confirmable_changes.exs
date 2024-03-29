defmodule <%= [:Haytni, "Migrations", camelized_scope, "ConfirmableChanges"] |> Module.concat() |> inspect() %> do
  use Ecto.Migration

  def change(table \\ <%= inspect(table) %>) do
    create_if_not_exists table(table) do
      # NOP
    end

    alter table(table) do
      add :confirmed_at, :utc_datetime, default: nil
    end
  end
end
