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
            {engine, extension} = cond do
              String.ends_with?(file, ".html.heex") ->
                {Phoenix.HTML.Engine, ".heex"}
              # TODO: remove support of ".html.eex"
              String.ends_with?(file, ".html.eex") ->
                {Phoenix.HTML.Engine, ".eex"}
              true ->
                {EEx.SmartEngine, ".eex"}
            end

            content =
              Path.join(path, file)
              |> EEx.eval_file(web_module: HaytniTestWeb, scope: scope, camelized_scope: scope |> to_string() |> Phoenix.Naming.camelize())
              |> EEx.compile_string(engine: engine)

            def render(unquote(Path.basename(file, extension)), var!(assigns)) do
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
