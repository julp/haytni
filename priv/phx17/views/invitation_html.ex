defmodule <%= [web_module, :Haytni, camelized_scope, "InvitationHTML"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext
  #require HaytniTestView

  #HaytniTestView.embed_templates_for_tests("priv/pxh17/templates/invitation/")

  embed_templates "invitation_html/*"
end
