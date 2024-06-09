defmodule <%= [web_module, :Haytni, camelized_scope, "ConfirmableEmails"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :html
  require Haytni.Gettext

  def confirmation_instructions_subject(_assigns) do
    Haytni.Gettext.dgettext("haytni", "Please confirm your account")
  end

  def reconfirmation_instructions_subject(_assigns) do
    Haytni.Gettext.dgettext("haytni", "Please confirm your email address change")
  end

  def email_changed_subject(_assigns) do
    Haytni.Gettext.dgettext("haytni", "Attention: email was changed")
  end

  embed_templates "confirmable_html/*.html", suffix: "_html"
  embed_templates "confirmable_text/*.text", suffix: "_text"
end
