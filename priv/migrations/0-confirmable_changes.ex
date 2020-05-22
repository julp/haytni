defmodule <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "ConfirmableChanges"]) %> do
  use Ecto.Migration

  def change do
    create_if_not_exists table(<%= inspect table %>) do
      # NOP
    end

    alter table(<%= inspect table %>) do
      add :confirmed_at, :utc_datetime, default: nil
      add :unconfirmed_email, :string, default: nil
      add :confirmation_token, :string, default: nil
      add :confirmation_sent_at, :utc_datetime, null: false
    end

    create index(<%= inspect table %>, ~W[confirmation_token]a, unique: true)
  end
end
