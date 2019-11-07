ExUnit.start()
Application.ensure_all_started(:haytni)

require EEx

~W[
  support/haytnitest_web.ex
  support/haytnitest_web/router.ex
  support/haytnitest_web/endpoint.ex
  support/haytnitest/user.ex
  support/haytnitest/mailer.ex
  support/haytnitest/application.ex
  support/haytnitest/repo.ex
  support/data_case.ex
  support/conn_case.ex
  support/test_helpers.ex
  support/haytnitest_web/views/error_helpers.ex
  support/haytnitest_web/views/error_view.ex
  support/haytnitest_web/gettext.ex
]
|> Enum.each(
  fn file ->
    Code.require_file(file, __DIR__)
  end
)

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
    |> EEx.eval_file(table: Haytni.schema().__schema__(:source))
    |> Code.compile_string()

    Ecto.Migrator.up(Haytni.repo(), number, module, log: false, all: true)

  end
)

{output, 0} = System.cmd("find", ["#{__DIR__}/../priv/views/", "-type", "f"])
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
Ecto.Adapters.SQL.Sandbox.mode(Haytni.repo(), :manual)
