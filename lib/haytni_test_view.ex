defmodule HaytniTestView do
  @moduledoc false

  defmacro embed_templates_for_tests(path) do
    with(
      ~W[HaytniTestWeb Haytni] <- Enum.take(Module.split(__CALLER__.module), 2),
      {:module, _module} <- Code.ensure_compiled(Mix),
      :test <- Mix.env()
    ) do
      quote bind_quoted: [path: path] do
        require EEx

        scope = HaytniTestWeb.Haytni.scope()
        path
        |> File.ls!()
        |> Enum.each(
          fn file ->
            engine = if String.ends_with?(file, ".html.eex") do
              Phoenix.HTML.Engine
            else
              EEx.SmartEngine
            end

            content = EEx.eval_file("#{path}/#{file}", web_module: HaytniTestWeb, scope: scope, camelized_scope: Phoenix.Naming.camelize(to_string(scope)))
            |> EEx.compile_string(engine: engine)

            def render(unquote(Path.basename(file, ".eex")), var!(assigns)) do
              unquote(content)
            end
          end
        )
      else
        _ ->
          nil
      end
    end
  end
end
