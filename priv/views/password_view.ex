defmodule <%= inspect web_module %>.Haytni.PasswordView do
  use <%= inspect web_module %>, :view
  require Haytni.Gettext
  require HaytniTestView

  HaytniTestView.embed_templates_for_tests("priv/templates/password/")
end
