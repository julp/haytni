defmodule <%= [web_module, :Haytni, camelized_scope, "SessionHTML"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  use Gettext, backend: Haytni.Gettext
  #require HaytniTestView

  #HaytniTestView.embed_templates_for_tests("priv/pxh17/templates/session/")

  embed_templates "session_html/*"
end
