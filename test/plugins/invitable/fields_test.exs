defmodule Haytni.Invitable.FieldsTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.InvitablePlugin,
  ]

  @reversed_associations ~W[sender accepter]a
  describe "Haytni.InvitablePlugin.fields/0 (callback)" do
    test "ensures invitations relation exists" do
      user_schema = HaytniTest.User
      assert :invitations in user_schema.__schema__(:associations)
      refute is_nil(user_schema.__schema__(:association, :invitations))

      invitation_schema = user_schema.__schema__(:association, :invitations).related
      assert "users_invitations" == invitation_schema.__schema__(:source)
      assert @reversed_associations == invitation_schema.__schema__(:associations)
      for assoc <- @reversed_associations do
        assert user_schema == invitation_schema.__schema__(:association, assoc).related
      end
    end
  end
end
