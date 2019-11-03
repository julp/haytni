ExUnit.start()
Application.ensure_all_started(:haytni)

require EEx

~W[
  haytni_test.exs
  support/haytnitest_web.ex
  support/haytnitest_web/router.ex
  support/haytnitest_web/endpoint.ex
  support/haytnitest/user.ex
  support/haytnitest/mailer.ex
  support/haytnitest/application.ex
  support/haytnitest/repo.ex
  support/conn_case.ex
  support/test_helpers.ex
  authenticable/authentificate_test.exs
  registerable/registerable_test.exs
]
|> Enum.each(
  fn file ->
    Code.require_file(file, __DIR__)
  end
)

if true do
  {:ok, _pid} = HaytniTest.Application.start(:unused, :unused)
else
  {:ok, _pid} = HaytniTestWeb.Endpoint.start_link()
  {:ok, _pid} = Haytni.repo().start_link()
end

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

assigns = %{
  user: %{email: "test@test.com", confirmation_token: "abcdef"}
}

IO.puts("\n==============================\n")

#HaytniTestWeb.Haytni.Email.ConfirmableView.render("test.html", assigns)
#|> IO.inspect()

#Phoenix.View.render_to_string(HaytniTestWeb.Haytni.Email.ConfirmableView, "test.html", assigns)
#|> IO.inspect()

HaytniTestWeb.Haytni.Email.ConfirmableView.render("confirmation_instructions.text", assigns)
|> IO.inspect()

Phoenix.View.render_to_string(HaytniTestWeb.Haytni.Email.ConfirmableView, "confirmation_instructions.text", assigns)
|> IO.inspect()
