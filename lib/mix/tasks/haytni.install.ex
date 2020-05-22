defmodule Mix.Tasks.Haytni.Install do
  use Mix.Task

  @switches [
    scope: :string,
    table: :string,
    plugin: [:string, :keep]
  ]

  def run(args) do
    {opts, _parsed, _unknown} = OptionParser.parse(args, switches: @switches)

    otp_app = Mix.Phoenix.otp_app()
    base_module = Module.concat([Mix.Phoenix.base()])
    web_module = Mix.Phoenix.web_module(base_module)
    scope_as_string = Keyword.get(opts, :scope, "user")
    plugins = Keyword.get_values(opts, :plugin)
    |> Enum.map(&(Module.concat([&1])))

    web_path = web_path()
    base_path = base_path()
    files_to_install = plugins
    |> Enum.reduce([], &(&1.files_to_install(base_path, web_path, scope_as_string) ++ &2))

    binding = Keyword.new()
    |> Keyword.put(:otp_app, otp_app)
    |> Keyword.put(:plugins, plugins)
    |> Keyword.put(:web_module, web_module)
    |> Keyword.put(:base_module, base_module)
    |> Keyword.put(:scope, String.to_atom(scope_as_string))
    |> Keyword.put(:table, Keyword.get(opts, :table, "users"))
    |> Keyword.put(:camelized_scope, Phoenix.Naming.camelize(scope_as_string))

    Mix.Phoenix.copy_from([".", :haytni], "priv/", binding, files_to_install)
  end

  # <from phoenix/lib/mix/tasks/phx.gen.schema.ex>
  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

  def timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end
  # </from phoenix/lib/mix/tasks/phx.gen.schema.ex>

  def base_path(path \\ "") do
    Path.join(["lib", to_string(Mix.Phoenix.otp_app()), path])
  end

  def web_path(path \\ "") do
    Path.join(["lib", "#{Mix.Phoenix.otp_app()}_web", path])
  end
end
