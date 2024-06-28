defmodule Haytni.Rolable.ChangeRoleTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RolablePlugin,
  ]

  describe "Haytni.RolablePlugin.change_role/1" do
    test "returns a Ecto.Changeset from module" do
      %Ecto.Changeset{} = @plugin.change_role(@stack)
    end

    test "returns a Ecto.Changeset from struct" do
      %Ecto.Changeset{} = @plugin.change_role(%HaytniTest.UserRole{})
    end
  end
end
