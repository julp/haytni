defmodule Haytni.Rolable.UpdateRoleTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RolablePlugin,
  ]

  defp role_params(attrs \\ []) do
    [
      name: "some name",
    ]
    |> Params.create(attrs)
  end

  describe "Haytni.RolablePlugin.update_role/2" do
    setup do
      role = role_fixture()

      binding()
    end

    test "success: updates a previous role", %{role: role} do
      {:ok, updated_role} = @plugin.update_role(@stack, role_params(), role)
      assert updated_role == @plugin.get_role!(@stack, role.id)
    end

    test "failure: error on invalid name", %{role: role} do
      {:error, changeset} = @plugin.update_role(@stack, role_params(name: ""), role)
      assert changeset.errors == [{:name, {"can't be blank", [validation: :required]}}]
      assert role == @plugin.get_role!(@stack, role.id)
    end

    test "failure: error on duplicated name", %{role: role} do
      other_role = role_fixture()

      {:error, changeset} = @plugin.update_role(@stack, role_params(name: other_role.name), role)
      assert changeset.errors == [{:name, {"has already been taken", [constraint: :unique, constraint_name: "users_roles_name_index"]}}]
      assert role == @plugin.get_role!(@stack, role.id)
    end
  end
end
