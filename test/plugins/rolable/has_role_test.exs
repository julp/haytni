defmodule Haytni.Rolable.HasRoleTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RolablePlugin,
  ]

  describe "Haytni.RolablePlugin.has_role?/2" do
    setup do
      [role1, role2, role3, role4, role5] =
        Enum.map(
          1..5,
          fn _ ->
            %HaytniTest.UserRole{name: Haytni.InvitablePlugin.random_code(8)}
          end
        )

      binding()
    end

    test "success: single role", %{role1: role1, role2: role2, role3: role3} do
      required = [role2.name] |> Enum.shuffle() |> MapSet.new()

      assert @plugin.has_role?(%HaytniTest.User{roles: [role2]}, required)
      assert @plugin.has_role?(%HaytniTest.User{roles: Enum.shuffle([role1, role2, role3])}, required)
    end

    test "success: multiple roles", %{role1: role1, role2: role2, role3: role3, role4: role4} do
      required = [role1.name, role3.name, role4.name] |> Enum.shuffle() |> MapSet.new()

      assert @plugin.has_role?(%HaytniTest.User{roles: Enum.shuffle([role3])}, required)
      assert @plugin.has_role?(%HaytniTest.User{roles: Enum.shuffle([role4])}, required)
      assert @plugin.has_role?(%HaytniTest.User{roles: Enum.shuffle([role1, role2, role3])}, required)
      assert @plugin.has_role?(%HaytniTest.User{roles: Enum.shuffle([role1, role2, role3, role4])}, required)
    end

    test "failure: single role missing", %{role1: role1, role2: role2, role3: role3, role4: role4, role5: role5} do
      required = [role1.name] |> Enum.shuffle() |> MapSet.new()

      refute @plugin.has_role?(%HaytniTest.User{roles: [role2]}, required)
      refute @plugin.has_role?(%HaytniTest.User{roles: Enum.shuffle([role2, role3, role4, role5])}, required)
    end

    test "failure: multiple roles missing", %{role1: role1, role2: role2, role3: role3, role4: role4, role5: role5} do
      required = [role4.name, role5.name] |> Enum.shuffle() |> MapSet.new()

      refute @plugin.has_role?(%HaytniTest.User{roles: Enum.shuffle([role1, role2, role3])}, required)
    end
  end
end
