defmodule <%= inspect web_module %>.Haytni.Email.ConfirmableView do
  use <%= inspect web_module %>, :view
  require HaytniTestView

  HaytniTestView.embed_templates_for_tests("priv/templates/email/confirmable/")
end
