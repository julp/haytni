defmodule <%= [:Haytni, "Migrations", camelized_scope, "LastSeenChanges"] |> Module.concat() |> inspect() %> do
  use Ecto.Migration

  def change(users_table \\ <%= inspect(table) %>) do
    create_if_not_exists table(users_table) do
      # NOP
    end

    alter table(users_table) do
      add :current_sign_in_at, :utc_datetime, default: nil
      add :last_sign_in_at, :utc_datetime, default: nil
    end
  end
end
