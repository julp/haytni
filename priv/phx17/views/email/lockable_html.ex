defmodule <%= [web_module, :Haytni, camelized_scope, "LockableHTML"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext

  embed_templates "lockable_html/*"
end
