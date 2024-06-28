defmodule Haytni.Rolable.UserQueryTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RolablePlugin,
  ]

#   import Ecto.Query

  describe "Haytni.RolablePlugin.user_query/3 (callback)" do
    test "" do
#       config = :unused
      role = role_fixture()
      user = user_fixture(roles: [role])
      user_with_roles = Haytni.get_user(@stack, user.id)

      assert [role] == user_with_roles.roles
#       from(@stack.schema, as: :user) |> @plugin.user_query(@stack, config)
    end
  end
end
