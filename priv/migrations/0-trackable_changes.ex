defmodule Haytni.Migrations.TrackableChanges do
  use Ecto.Migration

  def change(table \\ <%= inspect table %>, scope \\ <%= inspect scope %>) do
    create_if_not_exists table(table) do
      # NOP
    end

    alter table(table) do
      add :current_sign_in_at, :utc_datetime, default: nil
      add :last_sign_in_at, :utc_datetime, default: nil
    end

    fk = :"#{scope}_id"
    create table("#{scope}_connections") do
      add fk, references(table), on_delete: :delete_all, on_update: :update_all
      add :ip, :inet, null: false
      timestamps(updated_at: false)
    end

    create index("#{scope}_connections", [fk])
  end
end
