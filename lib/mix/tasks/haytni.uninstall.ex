defmodule Mix.Tasks.Haytni.Uninstall do
  use Mix.Task
  import Mix.Tasks.Haytni.Install, only: [base_path: 0, web_path: 0]

  @switches [
    scope: :string,
    plugin: [:string, :keep]
  ]

  def run(args) do
    {opts, _parsed, _unknown} = OptionParser.parse(args, switches: @switches)

    web_path = web_path()
    base_path = base_path()
    scope_as_string = Keyword.get(opts, :scope, "user")
    Keyword.get_values(opts, :plugin)
    |> Enum.map(&(Module.concat([&1])))
    |> Enum.reduce([], &(&1.files_to_install(base_path, web_path, scope_as_string, "<UNUSED>") ++ &2))
    |> rm_from()
  end

  def rm_from(mapping) when is_list(mapping) do
    for {_format, _source_file_path, target} <- mapping do
      # NOTE: it is intended from File.rm to fail on migrations (it would need a wildcard to find the actual filename of a migration)
      # In fact we want to keep them in order to be able to rollback them
      File.rm(target)
    end
  end
end
