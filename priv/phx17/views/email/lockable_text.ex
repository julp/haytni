defmodule <%= [web_module, :Haytni, camelized_scope, "LockableTEXT"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext

  embed_templates "lockable_text/*"
end
