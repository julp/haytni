defmodule <%= [web_module, :Haytni, camelized_scope, "Email", "InvitableView"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :view
  require HaytniTestView

  HaytniTestView.embed_templates_for_tests("priv/phx16/templates/email/invitable/")
end
