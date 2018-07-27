defmodule Haytni.Migrations.LockableChanges do
  use Ecto.Migration

  def change do
    alter table(<%= inspect table %>) do
      add :locked_at, :utc_datetime, default: nil
      add :failed_attempts, :integer, default: 0, null: false
      add :unlock_token, :string, default: nil
    end

    create index(<%= inspect table %>, ~W[unlock_token]a, unique: true)
  end
end
