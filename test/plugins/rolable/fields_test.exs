defmodule Haytni.Rolable.FieldsTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RolablePlugin,
  ]

  describe "Haytni.RolablePlugin.fields/0 (callback)" do
    for(
      {roles_table, _association_table, user_schema} <- [
        {"users_roles", "users_roles__assoc", HaytniTest.User},
#         {"admins_roles", "admins_roles__assoc", HaytniTest.Admin},
      ]
    ) do
      test "ensures roles relation exists for #{user_schema}" do
        assert :roles in unquote(user_schema).__schema__(:associations)
        refute is_nil(unquote(user_schema).__schema__(:association, :roles))

        roles_schema = unquote(user_schema).__schema__(:association, :roles).related
        assert unquote(roles_table) == roles_schema.__schema__(:source)
      end
    end
  end
end
