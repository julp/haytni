defmodule <%= inspect Module.concat([base_module, :Haytni, camelized_scope, "QuickViewsAndTemplatesTest"]) %> do
  use ExUnit.Case, async: true

  test "quick testing of your Haytni views and templates" do
    Haytni.QuickViewsAndTemplatesTest.check_views_and_templates(<%= inspect base_module %>.Haytni)
  end
end
