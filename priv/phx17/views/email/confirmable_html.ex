defmodule <%= [web_module, :Haytni, camelized_scope, "ConfirmableHTML"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext

  embed_templates "confirmable_html/*"
end
