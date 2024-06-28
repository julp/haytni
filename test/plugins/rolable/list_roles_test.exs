defmodule Haytni.Rolable.ListRolesTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RolablePlugin,
  ]

  defp sort_roles(roles) do
    Enum.sort_by(roles, &(&1.id))
  end

  describe "Haytni.RolablePlugin.list_roles/1" do
    test "all roles are listed" do
      assert [] == @plugin.list_roles(@stack)
      role1 = role_fixture()
      assert [role1] == @plugin.list_roles(@stack)
    end
  end

  describe "Haytni.RolablePlugin.list_roles/2" do
    test "only wanted roles are listed" do
      inexistant_role = %HaytniTest.UserRole{id: 42}
      [role1, role2, role3] = Enum.map(1..3, fn i -> role_fixture(id: i) end)

      assert [role2] == @plugin.list_roles(@stack, [role2.id, inexistant_role.id] |> Enum.map(&to_string/1))
      assert [role1, role3] == @plugin.list_roles(@stack, [role3.id, inexistant_role.id, role1.id] |> Enum.map(&to_string/1)) |> sort_roles()
    end
  end
end
