defmodule <%= inspect web_module %>.Haytni.Email.ConfirmableView do
  use <%= inspect web_module %>, :view

  if Code.ensure_compiled?(Mix) and Mix.env() == :test do
    require EEx

    path = "priv/templates/email/confirmable/"

    path
    |> File.ls!()
    |> Enum.map(
      fn file ->
        engine = cond do
          String.ends_with?(file, ".html.eex") ->
            Phoenix.HTML.Engine
          true ->
            EEx.SmartEngine
        end

        content = EEx.eval_file("#{path}/#{file}", web_module: HaytniTestWeb)
        |> EEx.compile_string(engine: engine)

        def render(unquote(Path.basename(file, ".eex")), assigns) do
          unquote(content)
        end
      end
    )
  end
end
