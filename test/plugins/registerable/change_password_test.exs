defmodule Haytni.Registerable.ChangePasswordTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RegisterablePlugin,
  ]

  describe "Haytni.RegisterablePlugin.change_password/3" do
    setup do
      [
        config: @plugin.build_config(),
      ]
    end

    test "empty changeset" do
      assert %Ecto.Changeset{} = @plugin.change_password(@stack, %HaytniTest.User{})
    end
  end
end
