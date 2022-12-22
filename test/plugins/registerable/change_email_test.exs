defmodule Haytni.Registerable.ChangeEmailTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RegisterablePlugin,
  ]

  describe "Haytni.RegisterablePlugin.change_email/4" do
    setup do
      [
        config: @plugin.build_config(),
      ]
    end

    test "empty changeset", %{config: config} do
      assert %Ecto.Changeset{} = @plugin.change_email(@stack, config, %HaytniTest.User{})
    end
  end
end
