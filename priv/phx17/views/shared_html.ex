defmodule <%= [web_module, :Haytni, camelized_scope, "SharedHTML"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext
  #require HaytniTestView

  #HaytniTestView.embed_templates_for_tests("priv/phx17/templates/shared/")

  embed_templates "shared_html/*"
end
