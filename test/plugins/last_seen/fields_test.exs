defmodule Haytni.LastSeen.FieldsTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.LastSeenPlugin,
  ]

  @fields ~W[last_sign_in_at current_sign_in_at]a
  describe "Haytni.LastSeenPlugin.fields/0 (callback)" do
    test "ensures User schema contains necessary fields" do
      user = %HaytniTest.User{}

      assert contains?(Map.keys(user), @fields)
    end

    test "ensures User struct contains necessary fields" do
      assert contains?(HaytniTest.User.__schema__(:fields), @fields)
    end
  end
end
