defmodule Haytni.Rememberable.FieldsTest do
  use HaytniWeb.ConnCase, async: true

  @fields ~W[remember_token remember_created_at]a
  describe "Haytni.RememberablePlugin.fields/0 (callback)" do
    test "ensures User schema contains necessary fields" do
      user = %HaytniTest.User{}

      assert contains(Map.keys(user), @fields)
    end

    test "ensures User struct contains necessary fields" do
      assert contains(HaytniTest.User.__schema__(:fields), @fields)
    end
  end
end
