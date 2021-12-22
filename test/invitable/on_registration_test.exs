defmodule Haytni.Invitable.OnRegistrationTest do
  use Haytni.DataCase, async: true
  use Bamboo.Test

  describe "Haytni.InvitablePlugin.on_registration/3" do
    setup do
      [
        sender: user_fixture(),
        config: Haytni.InvitablePlugin.build_config(invitation_required: true),
      ]
    end

    for email_match <- [true, false], invitation_required <- [true, false] do
      test "valid invitation with same address is accepted regardless of email_matching_invitation (#{inspect(email_match)}) and invitation_required (#{inspect(invitation_required)})", %{sender: sender, config: config} do
        invitation = invitation_fixture(sender, "abc.def@ghi")
        accepter = %HaytniTest.User{email: invitation.sent_to, invitation: invitation.code}

        actions =
          Ecto.Multi.new()
          |> Haytni.InvitablePlugin.on_registration(HaytniTestWeb.Haytni, %{config | email_matching_invitation: unquote(email_match), invitation_required: unquote(invitation_required)})
          |> Ecto.Multi.to_list()

        assert [{:acceptation, {:run, fun}}] = actions
        assert {:ok, true} = fun.(HaytniTest.Repo, %{user: accepter})

        assert [updated_invitation] = list_invitations(HaytniTestWeb.Haytni, sender)
        assert updated_invitation.id == invitation.id
        #assert updated_invitation.accepted_by == accepter.id # NOTE: we can't check that here since accepter is not persisted (and its id is nil)
        refute is_nil(updated_invitation.accepted_at)
      end
    end

    test "invitation required, one was provided but email address doesn't match (email_matching_invitation = true)", %{sender: sender, config: config} do
      invitation = invitation_fixture(sender, "abc.def@ghi", code: "azerty")
      accepter = %HaytniTest.User{email: String.reverse(invitation.sent_to), invitation: invitation.code}

      actions =
        Ecto.Multi.new()
        |> Haytni.InvitablePlugin.on_registration(HaytniTestWeb.Haytni, %{config | email_matching_invitation: true})
        |> Ecto.Multi.to_list()

      assert [{:acceptation, {:run, fun}}] = actions
      assert {:error, :invitation_required} = fun.(HaytniTest.Repo, %{user: accepter})
    end

    test "invitation is optional and none provided", %{config: config} do
      accepter = %HaytniTest.User{email: "abracadabra@magic.com", invitation: nil}

      actions =
        Ecto.Multi.new()
        |> Haytni.InvitablePlugin.on_registration(HaytniTestWeb.Haytni, %{config | invitation_required: false})
        |> Ecto.Multi.to_list()

      assert [{:acceptation, {:run, fun}}] = actions
      assert {:ok, false} = fun.(HaytniTest.Repo, %{user: accepter})
    end

    test "invitation required but none provided", %{config: config} do
      accepter = %HaytniTest.User{email: "abracadabra@magic.com", invitation: nil}

      actions =
        Ecto.Multi.new()
        |> Haytni.InvitablePlugin.on_registration(HaytniTestWeb.Haytni, config)
        |> Ecto.Multi.to_list()

      assert [{:acceptation, {:run, fun}}] = actions
      assert {:error, :invitation_required} = fun.(HaytniTest.Repo, %{user: accepter})
    end

    test "invitation required but has expired", %{sender: sender, config: config} do
      invitation = invitation_fixture(sender, "abc.def@ghi", sent_at: config.invitation_within + 1)
      accepter = %HaytniTest.User{email: invitation.sent_to, invitation: invitation.code}

      actions =
        Ecto.Multi.new()
        |> Haytni.InvitablePlugin.on_registration(HaytniTestWeb.Haytni, config)
        |> Ecto.Multi.to_list()

      assert [{:acceptation, {:run, fun}}] = actions
      assert {:error, :invitation_required} = fun.(HaytniTest.Repo, %{user: accepter})
    end

    test "invitation optional and has expired", %{sender: sender, config: config} do
      invitation = invitation_fixture(sender, "abc.def@ghi", sent_at: config.invitation_within + 1)
      accepter = %HaytniTest.User{email: invitation.sent_to, invitation: invitation.code}

      actions =
        Ecto.Multi.new()
        |> Haytni.InvitablePlugin.on_registration(HaytniTestWeb.Haytni, %{config | invitation_required: false})
        |> Ecto.Multi.to_list()

      assert [{:acceptation, {:run, fun}}] = actions
      assert {:ok, false} = fun.(HaytniTest.Repo, %{user: accepter})
    end

    test "invitation required but was already used", %{sender: sender, config: config} do
      invitation = invitation_fixture(sender, "abc.def@ghi", accepted_by: sender)
      accepter = %HaytniTest.User{email: invitation.sent_to, invitation: invitation.code}

      actions =
        Ecto.Multi.new()
        |> Haytni.InvitablePlugin.on_registration(HaytniTestWeb.Haytni, config)
        |> Ecto.Multi.to_list()

      assert [{:acceptation, {:run, fun}}] = actions
      assert {:error, :invitation_required} = fun.(HaytniTest.Repo, %{user: accepter})
    end

    test "invitation optional and was already used", %{sender: sender, config: config} do
      invitation = invitation_fixture(sender, "abc.def@ghi", accepted_by: sender)
      accepter = %HaytniTest.User{email: invitation.sent_to, invitation: invitation.code}

      actions =
        Ecto.Multi.new()
        |> Haytni.InvitablePlugin.on_registration(HaytniTestWeb.Haytni, %{config | invitation_required: false})
        |> Ecto.Multi.to_list()

      assert [{:acceptation, {:run, fun}}] = actions
      assert {:ok, false} = fun.(HaytniTest.Repo, %{user: accepter})
    end
  end
end
