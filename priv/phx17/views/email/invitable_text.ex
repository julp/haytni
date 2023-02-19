defmodule <%= [web_module, :Haytni, camelized_scope, "InvitableTEXT"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext

  embed_templates "invitable_text/*"
end
