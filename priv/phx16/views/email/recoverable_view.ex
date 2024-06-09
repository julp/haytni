defmodule <%= [web_module, :Haytni, camelized_scope, "Email", "RecoverableView"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :view
  require HaytniTestView
  require Haytni.Gettext

  def reset_password_instructions_subject(_assigns) do
    Haytni.Gettext.dgettext("haytni", "Reset password instructions")
  end

  HaytniTestView.embed_templates_for_tests("priv/phx16/templates/email/recoverable/")
end
