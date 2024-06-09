defmodule <%= [web_module, :Haytni, camelized_scope, "InvitableEmails"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext

  def invitation_subject(_assigns) do
    Haytni.Gettext.dgettext("haytni", "You've been invited")
  end

  embed_templates "invitable_html/*.html", suffix: "_html"
  embed_templates "invitable_text/*.text", suffix: "_text"
end
