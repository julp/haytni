ExUnit.start()
Application.ensure_all_started(:haytni)

require EEx

##### user scope #####

scope = HaytniTestWeb.Haytni.scope()
binding = [
  scope: scope,
  web_module: HaytniTestWeb,
  camelized_scope: Phoenix.Naming.camelize(to_string(scope)),
  table: HaytniTestWeb.Haytni.schema().__schema__(:source),
]
{:ok, _pid} = HaytniTest.Application.start(:unused, :unused)

phoenix_view_root = Path.join([__DIR__, "..", "priv", "phx16", "views"])
migration_root = Path.join([__DIR__, "..", "priv", "migrations"])

migration_root
|> File.ls!()
|> Enum.sort()
# Generate a dummy incremented number to apply all migrations
# Because if you use twice the same number, only the first one will be applied
|> Enum.with_index()
|> Enum.each(
  fn {migration, number} ->
    module = Haytni.TestHelpers.onfly_module_from_eex(Path.join(migration_root, migration), binding)
    Ecto.Migrator.up(HaytniTestWeb.Haytni.repo(), number, module, log: false, all: true)
  end
)

{output, 0} = case :os.type() do
  {:unix, _family} ->
    System.cmd("find", [phoenix_view_root, "-type", "f"])
  {:win32, _family} ->
    System.cmd("dir", [phoenix_view_root, "/b"])
end
output
|> String.split("\n", trim: true)
|> Stream.map(&String.trim/1)
|> Enum.each(
  fn view ->
    # NOTE: a "hack" for ignored views when migrating Phoenix
    try do
      Haytni.TestHelpers.onfly_module_from_eex(view, binding)
    rescue
      MatchError ->
        nil
    end
  end
)

##### admin scope #####

scope = HaytniTestWeb.HaytniAdmin.scope()
binding = [
  scope: scope,
  web_module: HaytniTestWeb,
  camelized_scope: Phoenix.Naming.camelize(to_string(scope)),
  table: HaytniTestWeb.HaytniAdmin.schema().__schema__(:source),
]

~W[0-tokens_creation.exs 0-lockable_changes.exs]
|> Enum.reduce(
  42,
  fn migration, acc ->
    module = Haytni.TestHelpers.onfly_module_from_eex(Path.join(migration_root, migration), binding)
    Ecto.Migrator.up(HaytniTestWeb.Haytni.repo(), acc, module, log: false, all: true)
    acc + 1
  end
)

# A scoped view (HaytniTestWeb.Haytni.Admin.SessionView)
Haytni.TestHelpers.onfly_module_from_eex(Path.join(phoenix_view_root, "session_view.ex"), binding)
# Simulate a shared view (HaytniTestWeb.Haytni.UnlockView)
Haytni.TestHelpers.onfly_module_from_eex(Path.join(phoenix_view_root, "unlock_view.ex"), binding |> Keyword.put(:scope, nil) |> Keyword.put(:camelized_scope, nil))

Process.flag(:trap_exit, true)
Ecto.Adapters.SQL.Sandbox.mode(HaytniTest.Repo, :manual)
