defmodule <%= [web_module, :Haytni, camelized_scope, "RecoverableEmails"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  use Gettext, backend: Haytni.Gettext

  def reset_password_instructions_subject(_assigns) do
    dgettext("haytni", "Reset password instructions")
  end

  embed_templates "recoverable_html/*.html", suffix: "_html"
  embed_templates "recoverable_text/*.text", suffix: "_text"
end
