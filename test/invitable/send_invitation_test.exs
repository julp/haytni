defmodule Haytni.Invitable.SendInvitationTest do
  use Haytni.DataCase, [
    email: true,
    plugin: Haytni.InvitablePlugin,
  ]

  @email "abc@def.ghi"
  @valid_params %{"sent_to" => @email}
  describe "Haytni.InvitablePlugin.send_invitation/4" do
    setup do
      [
        user: user_fixture(),
        config: @plugin.build_config(invitation_quota: {1, :total}),
      ]
    end

    test "ensures no invitation is sent if user quota is exceeded", %{user: user, config: config} do
      assert {:error, changeset} = @plugin.send_invitation(@stack, %{config | invitation_quota: {0, :total}}, @valid_params, user)
      refute changeset.valid?
      assert %{base: [@plugin.invitation_quota_exceeded_message(0)]} == errors_on(changeset)
    end

    test "ensures no invitation is sent if params are empty", %{user: user, config: config} do
      assert {:error, changeset} = @plugin.send_invitation(@stack, config, %{}, user)
      refute changeset.valid?
      assert %{sent_to: [empty_message()]} == errors_on(changeset)
    end

    test "ensures no invitation is sent if params are invalid", %{user: user, config: config} do
      assert {:error, changeset} = @plugin.send_invitation(@stack, config, %{"sent_to" => "not a valid email address"}, user)
      refute changeset.valid?
      assert %{sent_to: [invalid_format_message()]} == errors_on(changeset)
    end

    test "ensures no invitation is sent for duplicated email", %{user: user, config: config} do
      invitation_fixture(user, @email)

      assert {:error, changeset} = @plugin.send_invitation(@stack, %{config | invitation_quota: :infinity}, @valid_params, user)
      refute changeset.valid?
      assert %{sent_to: [already_took_message()]} == errors_on(changeset)
    end

    test "ensures invitation is inserted and sent if quota is not exceeded and params are valid", %{user: user, config: config} do
      assert {:ok, invitation = %_{id: id}} = @plugin.send_invitation(@stack, config, @valid_params, user)
      assert [%_{id: ^id}] = list_invitations(@stack, user)
      user
      |> Haytni.InvitableEmail.invitation_email(invitation, @stack, config)
      |> assert_email_was_sent()
    end
  end
end
