defmodule <%= [web_module, :Haytni, camelized_scope, "Email", "LockableView"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :view
  require HaytniTestView
  require Haytni.Gettext

  def unlock_instructions_subject(_assigns) do
    Haytni.Gettext.dgettext("haytni", "Unlock instructions")
  end

  HaytniTestView.embed_templates_for_tests("priv/phx16/templates/email/lockable/")
end
