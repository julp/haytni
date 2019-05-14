defmodule Haytni.Migrations.TrackableChanges do
  use Ecto.Migration

  def change do
    alter table(<%= inspect table %>) do
      add :current_sign_in_at, :utc_datetime, default: nil
      add :last_sign_in_at, :utc_datetime, default: nil
    end

    create table("connections") do
      add :user_id, references(<%= inspect table %>), on_delete: :delete_all, on_update: :update_all
      add :ip, :inet, null: false
      timestamps(updated_at: false)
    end

    create index("connections", [:user_id])
  end
end
