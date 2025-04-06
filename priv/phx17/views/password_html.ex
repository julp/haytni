defmodule <%= [web_module, :Haytni, camelized_scope, "PasswordHTML"] |> Module.concat() |> inspect() %> do
  require HaytniTestView
  use <%= inspect(web_module) %>, :html
  use Gettext, backend: Haytni.Gettext

  embed_templates "password_html/*"

  HaytniTestView.embed_templates_for_tests("priv/phx17/templates/password/")
end
