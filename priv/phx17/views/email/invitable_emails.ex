defmodule <%= [web_module, :Haytni, camelized_scope, "InvitableEmails"] |> Module.concat() |> inspect() %> do
  require HaytniTestView
  use <%= inspect(web_module) %>, :html
  use Gettext, backend: Haytni.Gettext

  def invitation_subject(_assigns) do
    dgettext("haytni", "You've been invited")
  end

  embed_templates "invitable_html/*.html", suffix: "_html"
  embed_templates "invitable_text/*.text", suffix: "_text"

  HaytniTestView.embed_templates_for_tests("priv/phx17/templates/email/invitable/", true)
end
