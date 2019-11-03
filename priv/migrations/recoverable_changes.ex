defmodule Haytni.Migrations.RecoverableChanges do
  use Ecto.Migration

  def change do
    create_if_not_exists table(<%= inspect table %>) do
      # NOP
    end

    alter table(<%= inspect table %>) do
      add :reset_password_token, :string, default: nil
      add :reset_password_sent_at, :utc_datetime, default: nil
    end

    create index(<%= inspect table %>, ~W[reset_password_token]a, unique: true)
  end
end
