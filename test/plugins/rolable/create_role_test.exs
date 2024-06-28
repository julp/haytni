defmodule Haytni.Rolable.CreateRoleTest do
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

  describe "Haytni.RolablePlugin.create_role/2" do
    test "success: creates a new role" do
      assert [] == @plugin.list_roles(@stack)
      {:ok, role} = @plugin.create_role(@stack, role_params())
      assert [role] == @plugin.list_roles(@stack)
    end

    test "failure: error on invalid name" do
      assert [] == @plugin.list_roles(@stack)
      {:error, changeset} = @plugin.create_role(@stack, role_params(name: ""))
      assert [] == @plugin.list_roles(@stack)
      assert changeset.errors == [{:name, {"can't be blank", [validation: :required]}}]
    end

    test "failure: error on duplicated name" do
      role = role_fixture()

      assert [role] == @plugin.list_roles(@stack)
      {:error, changeset} = @plugin.create_role(@stack, role_params(name: role.name))
      assert [role] == @plugin.list_roles(@stack)
      assert changeset.errors == [{:name, {"has already been taken", [constraint: :unique, constraint_name: "users_roles_name_index"]}}]
    end
  end
end
