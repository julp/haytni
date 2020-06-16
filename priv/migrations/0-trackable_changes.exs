defmodule <%= inspect Module.concat([:Haytni, "Migrations", camelized_scope, "TrackableChanges"]) %> do
  use Ecto.Migration

  def change(users_table \\ <%= inspect table %>, scope \\ <%= inspect to_string(scope) %>) do
    create_if_not_exists table(users_table) do
      # NOP
    end

    alter table(users_table) do
      add :current_sign_in_at, :utc_datetime, default: nil
      add :last_sign_in_at, :utc_datetime, default: nil
    end

    ip_opts = [null: false]
    {ip_type, ip_opts} = case repo().__adapter__() do
      Ecto.Adapters.Postgres ->
        {:inet, ip_opts}
      _ ->
        # NOTE: for MySQL, the ideal type would be to have a custom Ecto Type to store the result of its INET6_ATON function
        # (or an Elixir/Erlang equivalent) as VARBINARY(16) via `dump` and apply INET6_NTOA at `load`
        {:string, Keyword.put(ip_opts, :size, 39)}
    end

    fk = :"#{scope}_id"
    connections_table = "#{users_table}_connections"
    create table(connections_table) do
      add fk, references(users_table), null: false, on_delete: :delete_all, on_update: :update_all
      add :ip, ip_type, ip_opts
      timestamps(updated_at: false)
    end

    create index(connections_table, [fk])
  end
end
