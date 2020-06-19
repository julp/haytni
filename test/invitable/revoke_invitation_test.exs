if false do
  defmodule Haytni.Invitable.RevokeInvitationTest do
    use Haytni.DataCase, async: true

    defp invitation_in_database?(invitation) do
      Enum.any?(HaytniTest.Repo.all(invitation.__struct__), &(match?(^invitation, &1)))
    end

    describe "Haytni.InvitablePlugin.revoke_invitation/3" do
      test "ensures an unused invitation can be revoked" do
        user = user_fixture()
        invitation_fixture(user, "abc@def.ghi", accepted_by: user)
        invitation = invitation_fixture(user, "xyz@def.ghi")

        assert invitation_in_database?(invitation)
        assert Haytni.InvitablePlugin.revoke_invitation(HaytniTestWeb.Haytni, user, invitation.id)
        refute invitation_in_database?(invitation)
      end

      test "ensures a used invitation cannot be revoked" do
        user = user_fixture()
        invitation_fixture(user, "abc@def.ghi")
        invitation = invitation_fixture(user, "xyz@def.ghi", accepted_by: user)

        assert invitation_in_database?(invitation)
        refute Haytni.InvitablePlugin.revoke_invitation(HaytniTestWeb.Haytni, user, invitation.id)
        assert invitation_in_database?(invitation)
      end
    end
  end
end
