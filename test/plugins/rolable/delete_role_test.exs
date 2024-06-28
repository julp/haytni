defmodule Haytni.Rolable.DeleteRoleTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RolablePlugin,
  ]

  describe "Haytni.RolablePlugin.delete_role/2" do
    test "success: deletes given role" do
      role = role_fixture()
      assert [role] == @plugin.list_roles(@stack)
      {:ok, _role} = @plugin.delete_role(@stack, role)
      assert [] == @plugin.list_roles(@stack)
    end
  end
end
