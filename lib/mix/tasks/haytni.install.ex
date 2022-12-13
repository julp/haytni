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
    plugins =
      opts
      |> Keyword.get_values(:plugin)
      |> Enum.map(&(Module.concat([&1])))

    web_path = web_path()
    base_path = base_path()
    timestamp = timestamp()
    files_to_install =
      plugins
      |> Enum.reduce(
        Haytni.shared_files_to_install(base_path, web_path, scope_as_string, timestamp),
        &(&1.files_to_install(base_path, web_path, scope_as_string, timestamp) ++ &2)
      )

    binding =
      [
        otp_app: otp_app,
        plugins: plugins,
        web_module: web_module,
        base_module: base_module,
        scope: String.to_atom(scope_as_string),
        table: Keyword.get(opts, :table, "users"),
        camelized_scope: Phoenix.Naming.camelize(scope_as_string),
      ]

    #IO.inspect(otp_app, label: "otp_app")
    #IO.inspect(base_path, label: "base_path")
    #IO.inspect(in_umbrella?(base_path), label: "in_umbrella?")
    #IO.inspect(files_to_install, label: "files_to_install")
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

  # <from phoenix/installer/lib/phx_new/generator.ex>
if false do
  defp phoenix_path_prefix(true), do: "../../../"
  defp phoenix_path_prefix(false), do: ".."

  def in_umbrella?(app_path) do
    umbrella = Path.expand(Path.join([app_path, "..", ".."]))
    mix_path = Path.join(umbrella, "mix.exs")
    apps_path = Path.join(umbrella, "apps")

    File.exists?(mix_path) && File.exists?(apps_path)
  end
end
  # </from phoenix/installer/lib/phx_new/generator.ex>

  def base_path(path \\ "") do
    Path.join(["lib", to_string(Mix.Phoenix.otp_app()), path])
  end

  def web_path(path \\ "") do
    otp_app = Mix.Phoenix.otp_app() |> to_string()
    otp_app_path = if otp_app |> String.ends_with?("_web") do
      otp_app
    else
      "#{otp_app}_web"
    end
    Path.join(["lib", otp_app_path, path])
  end
end
