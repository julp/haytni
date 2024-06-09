defmodule <%= [web_module, :Haytni, camelized_scope, "LockableEmails"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext

  def unlock_instructions_subject(_assigns) do
    Haytni.Gettext.dgettext("haytni", "Unlock instructions")
  end

  embed_templates "lockable_html/*.html", suffix: "_html"
  embed_templates "lockable_text/*.text", suffix: "_text"
end
