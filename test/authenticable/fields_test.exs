defmodule Haytni.Authenticable.FieldsTest do
  use HaytniWeb.ConnCase, async: true

  @schema_fields ~W[email encrypted_password]a
  # NOTE: password is a virtual field so it exists into the struct but not in the schema
  @struct_fields @schema_fields ++ ~W[password]a
  describe "Haytni.AuthenticablePlugin.fields/0 (callback)" do
    test "ensures User schema contains necessary fields" do
      user = %HaytniTest.User{}

      assert contains(Map.keys(user), @struct_fields)
    end

    test "ensures User struct contains necessary fields" do
      assert contains(HaytniTest.User.__schema__(:fields), @schema_fields)
    end
  end
end
