defmodule <%= [web_module, :Haytni, camelized_scope, "RecoverableEmails"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext

  def reset_password_instructions_subject(_assigns) do
    Haytni.Gettext.dgettext("haytni", "Reset password instructions")
  end

  embed_templates "recoverable_html/*.html", suffix: "_html"
  embed_templates "recoverable_text/*.text", suffix: "_text"
end
