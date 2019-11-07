defmodule Haytni.Migrations.TestChanges do
  use Ecto.Migration

  def change do
    create_if_not_exists table(<%= inspect table %>) do
      # NOP
    end

    alter table(<%= inspect table %>) do
      add :dummy, :boolean, null: false, default: false
    end
  end
end
