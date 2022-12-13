defmodule Haytni.PasswordPolicy.BuildConfigTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.PasswordPolicyPlugin,
  ]

  describe "Haytni.PasswordPolicyPlugin.build_config/1" do
    test "checks password_classes_to_match option can be set to [0;4] but not > 4" do
      for i <- 0..4 do
        assert %Haytni.PasswordPolicyPlugin.Config{password_classes_to_match: ^i} = @plugin.build_config(password_classes_to_match: i)
      end
      assert_raise ArgumentError, "password_classes_to_match was overriden to 5 but it cannot be greater than 4", fn ->
        @plugin.build_config(password_classes_to_match: 5)
      end
    end
  end
end
