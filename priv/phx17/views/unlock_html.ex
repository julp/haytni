defmodule <%= [web_module, :Haytni, camelized_scope, "UnlockHTML"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext
  #require HaytniTestView

  #HaytniTestView.embed_templates_for_tests("priv/pxh17/templates/unlock/")

  embed_templates "unlock_html/*"
end
