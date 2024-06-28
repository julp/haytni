defmodule Haytni.Rolable.GetRoleTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RolablePlugin,
  ]

  describe "Haytni.RolablePlugin.get_role!/2" do
    test "success: fetch existant role" do
      role = role_fixture()
      assert role == @plugin.get_role!(@stack, role.id)
    end

    test "failure: raises on inexistant role" do
      assert_raise Ecto.NoResultsError, fn ->
        @plugin.get_role!(@stack, id())
      end
    end
  end
end
