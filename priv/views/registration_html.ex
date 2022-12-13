if Haytni.Helpers.phoenix17?() do
  defmodule <%= inspect Module.concat([web_module, :Haytni, camelized_scope, "RegistrationHTML"]) %> do
    use <%= inspect web_module %>, :html
    require Haytni.Gettext
    #require HaytniTestView

    #HaytniTestView.embed_templates_for_tests("priv/templates/registration/")

    embed_templates "registration_html/*"
  end
end
