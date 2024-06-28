defmodule <%= [web_module, :Haytni, camelized_scope, "RoleHTML"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext
  #require HaytniTestView

  #HaytniTestView.embed_templates_for_tests("priv/pxh17/templates/role/")

  embed_templates "role_html/*"
end
