defmodule <%= [web_module, :Haytni, camelized_scope, "ConfirmationView"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :view
  use Gettext, backend: Haytni.Gettext
  require HaytniTestView

  HaytniTestView.embed_templates_for_tests("priv/phx16/templates/confirmation/")
end
