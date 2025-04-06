defmodule <%= [web_module, :Haytni, camelized_scope, "LockableEmails"] |> Module.concat() |> inspect() %> do
  require HaytniTestView
  use <%= inspect(web_module) %>, :html
  use Gettext, backend: Haytni.Gettext

  def unlock_instructions_subject(_assigns) do
    dgettext("haytni", "Unlock instructions")
  end

  embed_templates "lockable_html/*.html", suffix: "_html"
  embed_templates "lockable_text/*.text", suffix: "_text"

  HaytniTestView.embed_templates_for_tests("priv/phx17/templates/email/lockable/", true)
end
