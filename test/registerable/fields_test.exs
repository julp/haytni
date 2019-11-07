defmodule Haytni.Registerable.FieldsTest do
  use HaytniWeb.ConnCase, async: true

  # NOTE: current_password is a virtual field so it exists into the struct but not in the schema
  @fields ~W[current_password]a
  describe "Haytni.RegisterablePlugin.fields/0 (callback)" do
    test "ensures User schema contains necessary fields" do
      user = %HaytniTest.User{}

      assert contains(Map.keys(user), @fields)
    end
  end
end
