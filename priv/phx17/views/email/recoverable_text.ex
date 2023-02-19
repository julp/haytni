defmodule <%= [web_module, :Haytni, camelized_scope, "RecoverableTEXT"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext

  embed_templates "recoverable_text/*"
end
