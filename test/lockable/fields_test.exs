defmodule Haytni.Lockable.FieldsTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.LockablePlugin,
  ]

  @fields Keyword.keys(@plugin.unlock_attributes())
  describe "Haytni.LockablePlugin.fields/0 (callback)" do
    test "ensures User schema contains necessary fields" do
      user = %HaytniTest.User{}

      assert contains?(Map.keys(user), @fields)
    end

    test "ensures User struct contains necessary fields" do
      assert contains?(HaytniTest.User.__schema__(:fields), @fields)
    end
  end
end
