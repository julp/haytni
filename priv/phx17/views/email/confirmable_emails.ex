defmodule <%= [web_module, :Haytni, camelized_scope, "ConfirmableEmails"] |> Module.concat() |> inspect() %> do
  require HaytniTestView
  use <%= inspect(web_module) %>, :html
  use Gettext, backend: Haytni.Gettext

  def confirmation_instructions_subject(_assigns) do
    dgettext("haytni", "Please confirm your account")
  end

  def reconfirmation_instructions_subject(_assigns) do
    dgettext("haytni", "Please confirm your email address change")
  end

  def email_changed_subject(_assigns) do
    dgettext("haytni", "Attention: email was changed")
  end

  embed_templates "confirmable_html/*.html", suffix: "_html"
  embed_templates "confirmable_text/*.text", suffix: "_text"

  HaytniTestView.embed_templates_for_tests("priv/phx17/templates/email/confirmable/", true)
end
