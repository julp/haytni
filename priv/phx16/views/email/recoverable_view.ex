defmodule <%= [web_module, :Haytni, camelized_scope, "Email", "RecoverableView"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :view
  require HaytniTestView
  use Gettext, backend: Haytni.Gettext

  def reset_password_instructions_subject(_assigns) do
    dgettext("haytni", "Reset password instructions")
  end

  HaytniTestView.embed_templates_for_tests("priv/phx16/templates/email/recoverable/")
end
