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
            {engine, extension, extension_phx_17} = cond do
              String.ends_with?(file, ".html.heex") ->
                {Phoenix.HTML.Engine, ".heex", ".html.heex"}
              # TODO: remove support of ".html.eex"
              String.ends_with?(file, ".html.eex") ->
                {Phoenix.HTML.Engine, ".eex", ".html.eex"}
              true ->
                {EEx.SmartEngine, ".eex", ".eex"}
            end

            content =
              Path.join(path, file)
              |> EEx.eval_file(
                [
                  plugins: [],
                  web_module: HaytniTestWeb,
                  scope: scope, camelized_scope: scope |> to_string() |> Phoenix.Naming.camelize(),
                ]
              )
              |> EEx.compile_string(engine: engine)

            if Haytni.Helpers.phoenix17?() do
              def unquote(Path.basename(file, extension_phx_17) |> String.to_atom())(var!(assigns)) do
                unquote(content)
              end
            else
              def render(unquote(Path.basename(file, extension)), var!(assigns)) do
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
end
