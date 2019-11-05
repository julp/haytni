defmodule HaytniTestView do
  defmacro embed_templates_for_tests(path) do
    if Application.fetch_env!(:haytni, :otp_app) == :haytni_test and Code.ensure_compiled?(Mix) and Mix.env() == :test do
      quote bind_quoted: [path: path] do
        require EEx

        path
        |> File.ls!()
        |> Enum.each(
          fn file ->
            engine = cond do
              String.ends_with?(file, ".html.eex") ->
                Phoenix.HTML.Engine
              true ->
                EEx.SmartEngine
            end

            content = EEx.eval_file("#{path}/#{file}", web_module: HaytniTestWeb)
            |> EEx.compile_string(engine: engine)

            def render(unquote(Path.basename(file, ".eex")), var!(assigns)) do
              unquote(content)
            end
          end
        )
      end
    end
  end
end
