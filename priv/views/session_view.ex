defmodule <%= inspect Module.concat([web_module, :Haytni, camelized_scope, "SessionView"]) %> do
  use <%= inspect web_module %>, :view
  require Haytni.Gettext
  require HaytniTestView

  HaytniTestView.embed_templates_for_tests("priv/templates/session/")
end
