defmodule Haytni.Trackable.FieldsTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.TrackablePlugin,
  ]

  @fields ~W[last_sign_in_at current_sign_in_at]a
  describe "Haytni.TrackablePlugin.fields/0 (callback)" do
    test "ensures User schema contains necessary fields" do
      user = %HaytniTest.User{}

      assert contains?(Map.keys(user), @fields)
    end

    test "ensures User struct contains necessary fields" do
      assert contains?(HaytniTest.User.__schema__(:fields), @fields)
    end

    for {association, table, user_schema} <- [{:user, "users_connections", HaytniTest.User}, {:admin, "admins_connections", HaytniTest.Admin}] do
      test "ensures connections relation exists for #{user_schema}" do
        assert :connections in unquote(user_schema).__schema__(:associations)
        refute is_nil(unquote(user_schema).__schema__(:association, :connections))

        connection_schema = unquote(user_schema).__schema__(:association, :connections).related
        assert unquote(table) == connection_schema.__schema__(:source)
        assert [unquote(association)] == connection_schema.__schema__(:associations)
        assert unquote(user_schema) == connection_schema.__schema__(:association, unquote(association)).related
      end
    end
  end
end
