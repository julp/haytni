defmodule Mix.Tasks.Haytni.Install do
  use Mix.Task

  @switches [
    scope: :string,
    table: :string,
    plugin: [:string, :keep]
  ]

  def run(args) do
    {opts, _parsed, _unknown} = OptionParser.parse(args, switches: @switches)
    files_to_install = case Keyword.get_values(opts, :plugin) do
      [] ->
        Haytni.plugins()
      plugins ->
        plugins
    end
    |> Enum.map(&(Module.concat([&1])))
    |> Enum.reduce([], &(&1.files_to_install() ++ &2))

    binding = Keyword.new
    |> Keyword.put(:web_module, web_module())
    |> Keyword.put(:scope, Keyword.get(opts, :scope, "user") |> String.to_atom())
    |> Keyword.put(:table, Keyword.get(opts, :table, "users"))

    Mix.Phoenix.copy_from([".", :haytni], "priv/", binding, files_to_install)
  end

  # from phoenix/lib/mix/tasks/phx.gen.schema.ex
  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

  def timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  # from phoenix/lib/mix/phoenix/context.ex
  defp web_module do
    base = Mix.Phoenix.base()
    cond do
      Mix.Phoenix.context_app() != Mix.Phoenix.otp_app() ->
        Module.concat([base])
      String.ends_with?(base, "Web") ->
        Module.concat([base])
      true ->
        Module.concat(["#{base}Web"])
    end
  end

  def web_path(path \\ "") do
    Path.join ["lib", "#{Mix.Phoenix.otp_app()}_web", path]
  end
end
