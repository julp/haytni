defmodule Haytni.Registerable.ChangePasswordTest do
  use Haytni.DataCase, async: true

  #@moduletag plugin: Haytni.RegisterablePlugin
  describe "Haytni.RegisterablePlugin.change_password/3" do
    setup do
      [
        module: HaytniTestWeb.Haytni,
        #plugin: Haytni.RegisterablePlugin,
        config: Haytni.RegisterablePlugin.build_config(),
      ]
    end

    test "empty changeset", %{module: module} do
      %Ecto.Changeset{} = Haytni.RegisterablePlugin.change_password(module, %HaytniTest.User{})
    end
  end
end
