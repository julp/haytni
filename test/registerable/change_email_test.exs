defmodule Haytni.Registerable.ChangeEmailTest do
  use Haytni.DataCase, async: true

  #@moduletag plugin: Haytni.RegisterablePlugin
  describe "Haytni.RegisterablePlugin.change_email/4" do
    setup do
      [
        module: HaytniTestWeb.Haytni,
        #plugin: Haytni.RegisterablePlugin,
        config: Haytni.RegisterablePlugin.build_config(),
      ]
    end

    test "empty changeset", %{module: module, config: config} do
      %Ecto.Changeset{} = Haytni.RegisterablePlugin.change_email(module, config, %HaytniTest.User{})
    end
  end
end
