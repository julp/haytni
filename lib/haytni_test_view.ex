defmodule HaytniTestView do
  @moduledoc false

  defmacro embed_templates_for_tests(path, with_suffix? \\ false) do
    with(
      ~W[HaytniTestWeb Haytni] <- Enum.take(Module.split(__CALLER__.module), 2),
      {:module, _module} <- Code.ensure_compiled(Mix),
      :test <- Mix.env()
    ) do
      require EEx

      scope = HaytniTestWeb.Haytni.scope()
      path
      |> File.ls!()
      |> Enum.map(
        fn file ->
          {engine, extension, suffix, options} =
            cond do
              String.ends_with?(file, ".html.heex") ->
                {Phoenix.LiveView.TagEngine, ".html.heex", "_html", tag_handler: Phoenix.LiveView.HTMLEngine}
              String.ends_with?(file, ".text.eex") ->
                {EEx.SmartEngine, ".text.eex", "_text", []}
            end

          source =
            Path.join(path, file)
            |> EEx.eval_file(
              [
                plugins: [],
                web_module: HaytniTestWeb,
                scope: scope, camelized_scope: scope |> to_string() |> Phoenix.Naming.camelize(),
              ]
            )

          content =
            EEx.compile_string(
              source,
              [
                line: 1,
                source: source,
                engine: engine,
                caller: __CALLER__,
                file: Path.join(path, file),
              ] ++ options
            )

          quote do
            def unquote([Path.basename(file, extension), with_suffix? && suffix || nil] |> Enum.join() |> String.to_atom())(var!(assigns)) do
              unquote(content)
            end
          end
        end
      )
    else
      _ ->
        nil
    end
  end
end
