defmodule <%= [web_module, :Haytni, camelized_scope, "RecoverableHTML"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext

  embed_templates "recoverable_html/*"
end
