defmodule <%= [web_module, :Haytni, camelized_scope, "RecoverableEmails"] |> Module.concat() |> inspect() %> do
  require HaytniTestView
  use <%= inspect(web_module) %>, :html
  use Gettext, backend: Haytni.Gettext

  def reset_password_instructions_subject(_assigns) do
    dgettext("haytni", "Reset password instructions")
  end

  embed_templates "recoverable_html/*.html", suffix: "_html"
  embed_templates "recoverable_text/*.text", suffix: "_text"

  HaytniTestView.embed_templates_for_tests("priv/phx17/templates/email/recoverable/", true)
end
