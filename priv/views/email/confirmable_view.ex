defmodule <%= inspect web_module %>.Haytni.Email.ConfirmableView do
  use <%= inspect web_module %>, :view

  if Code.ensure_compiled?(Mix) and Mix.env() == :test do
    require EEx

    #path = "#{__DIR__}/../../templates/email/confirmable/"
    path = "priv/templates/email/confirmable/"
    path
    |> File.ls!()
    |> Enum.map(
      fn file ->
        #extension = Path.extname(file)
        #|> String.trim_leading(".")
        #|> String.to_atom()

        engine = cond do
          String.ends_with?(file, ".html.eex") ->
            Phoenix.HTML.Engine
          true ->
            EEx.SmartEngine
        end
        #EEx.function_from_file(:def, :render, "#{path}/#{file}", [:template, :assigns])
        #Phoenix.Template.EExEngine.compile("#{path}/#{file}", Path.basename(file, ".eex"))
        content = EEx.eval_file("#{path}/#{file}", web_module: HaytniTestWeb)
        #engine = Map.fetch!(Phoenix.Template.engines(), extension)
        #engine.compile(
        |> EEx.compile_string(engine: engine)
        #|> IO.inspect()

        def render(unquote(Path.basename(file, ".eex")), assigns) do
          #EEx.compile_string(unquote(content), engine: Phoenix.HTML.Engine)
          unquote(content)
        end
        #|> IO.inspect()
        #Macro.to_string(content)

        #Path.basename(file, ".eex")
        # <=>
        #Phoenix.Template.template_path_to_name("#{path}/#{file}", path)
      end
    )
    #|> Enum.join()
    #|> unquote()

    #def render("test.html", assigns) do
      #~E"""
      #Hello <%%= @user.email %>
      #"""
    #end
  end
end
