defmodule Mix.Tasks.Haytni.Uninstall do
  use Mix.Task

  @switches [
    plugin: [:string, :keep]
  ]

  def run(args) do
    {opts, _parsed, _unknown} = OptionParser.parse(args, switches: @switches)
    case Keyword.get_values(opts, :plugin) do
      [] ->
        Haytni.plugins()
      plugins ->
        plugins
    end
    |> Enum.map(&(Module.concat([&1])))
    |> Enum.reduce([], &(&1.files_to_install() ++ &2))
    |> rm_from()
  end

  def rm_from(mapping) when is_list(mapping) do
    for {_format, _source_file_path, target} <- mapping do
      File.rm(target)
    end
  end
end
