defmodule <%= [web_module, :Haytni, camelized_scope, "Email", "InvitableView"] |> Module.concat() |> inspect() %> do
  use <%= inspect(web_module) %>, :view
  require HaytniTestView
  use Gettext, backend: Haytni.Gettext

  def invitation_subject(_assigns) do
    dgettext("haytni", "You've been invited")
  end

  HaytniTestView.embed_templates_for_tests("priv/phx16/templates/email/invitable/")
end
