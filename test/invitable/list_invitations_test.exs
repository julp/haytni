if false do
  defmodule Haytni.Invitable.ListInvitationsTest do
    use Haytni.DataCase, async: true

    describe "Haytni.InvitablePlugin.list_invitations/2" do
      test "list_invitations/2 returns all invitations associated to a user" do
        user1 = user_fixture()
        user2 = user_fixture()
        code1 = "0000"
        code2 = "1111"

        %_{id: id1, code: ^code1} = invitation_fixture(user1, "abc@def.ghi", code: code1, sent_at: -10, accepted_by: user2)
        %_{id: id2, code: ^code2} = invitation_fixture(user1, "xyz@def.ghi", code: code2)

        assert [%_{id: ^id2, code: ^code2}, %_{id: ^id1, code: ^code1}] = Haytni.InvitablePlugin.list_invitations(HaytniTestWeb.Haytni, user1)
        assert [] == Haytni.InvitablePlugin.list_invitations(HaytniTestWeb.Haytni, user2)
      end
    end
  end
end
