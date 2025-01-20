defmodule <%= [web_module, :Haytni, camelized_scope, "Email", "ConfirmableView"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :view
  require HaytniTestView
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

  HaytniTestView.embed_templates_for_tests("priv/phx16/templates/email/confirmable/")
end
