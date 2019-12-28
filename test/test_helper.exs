ExUnit.start()
Application.ensure_all_started(:haytni)

require EEx

{:ok, _pid} = HaytniTest.Application.start(:unused, :unused)

path = "#{__DIR__}/../priv/migrations/"
path
|> File.ls!()
|> Enum.sort()
# Generate a dummy incremented number to apply all migrations
# Because if you use twice the same number, only the first one will be applied
|> Enum.with_index()
|> Enum.each(
  fn {file, number} ->
    [{module, _binary}] = "#{path}/#{file}"
    |> EEx.eval_file(table: HaytniTestWeb.Haytni.schema().__schema__(:source), scope: HaytniTestWeb.Haytni.scope())
    |> Code.compile_string()

    Ecto.Migrator.up(HaytniTestWeb.Haytni.repo(), number, module, log: false, all: true)
  end
)

{output, 0} = case :os.type() do
  {:unix, _family} ->
    System.cmd("find", ["#{__DIR__}/../priv/views", "-type", "f"])
  {:win32, _family} ->
    System.cmd("dir", ["#{__DIR__}\\..\\priv\\views", "/b"])
end
output
|> String.split("\n", trim: true)
|> Stream.map(&String.trim/1)
|> Enum.each(
  fn file ->
    [{_module, _binary}] = EEx.eval_file(file, web_module: HaytniTestWeb)
    |> Code.compile_string()
  end
)

Process.flag(:trap_exit, true)
Ecto.Adapters.SQL.Sandbox.mode(HaytniTest.Repo, :manual)
