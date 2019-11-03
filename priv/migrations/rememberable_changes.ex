defmodule Haytni.Migrations.RememberableChanges do
  use Ecto.Migration

  def change do
    create_if_not_exists table(<%= inspect table %>) do
      # NOP
    end

    alter table(<%= inspect table %>) do
      add :remember_token, :string, default: nil
      add :remember_created_at, :utc_datetime, default: nil
    end

    create index(<%= inspect table %>, ~W[remember_token]a, unique: true)
  end
end
