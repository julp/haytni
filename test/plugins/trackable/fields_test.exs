defmodule Haytni.Trackable.FieldsTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.TrackablePlugin,
  ]

  describe "Haytni.TrackablePlugin.fields/0 (callback)" do
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
