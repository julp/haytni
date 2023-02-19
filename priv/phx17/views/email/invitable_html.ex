defmodule <%= [web_module, :Haytni, camelized_scope, "InvitableHTML"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext

  embed_templates "invitable_html/*"
end
