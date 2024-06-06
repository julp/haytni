defmodule Haytni.Invitable.ValidateCreateRegistrationTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.InvitablePlugin,
  ]

  @code "0123456789"
  @email "abc@def.ghi"
  @bad_email String.reverse(@email)

  defp put_unless_nil(map, _key, nil), do: map
  defp put_unless_nil(map, key, value), do: Map.put(map, key, value)

  defp to_changeset(invitation, email, config) do
    params = %{email: email}
    |> put_unless_nil(:invitation, invitation)

    %HaytniTest.User{}
    |> Ecto.Changeset.cast(params, ~W[invitation email]a)
    #|> Map.put(:repo, HaytniTest.Repo) # simulates Repo.insert call
    |> @plugin.validate_create_registration(@stack, config)
    |> HaytniTest.Repo.insert()
  end

  describe "Haytni.InvitablePlugin.validate_create_registration/3" do
    setup do
      user = user_fixture()
      invitation = invitation_fixture(user, @email, code: @code)

      [
        user: user,
        invitation: invitation,
        config: @plugin.build_config(),
      ]
    end

    test "ensures registration is possible without invitation when invitation_required = false", %{config: config} do
      assert catch_error(to_changeset(nil, @bad_email, %{config | invitation_required: false}))
    end

    test "ensures registration is not possible without invitation when invitation_required = true", %{config: config} do
      {:error, changeset} = to_changeset(nil, @bad_email, config)

      refute changeset.valid?
      assert %{base: [@plugin.invitation_required_message()]} == errors_on(changeset)
    end

    test "ensures registration is not possible with a bad code (invitation_required = true)", %{config: config} do
      {:error, changeset} = to_changeset("abcdefghijklmnopqrstuvwxyz", @bad_email, config)

      refute changeset.valid?
      assert %{base: [@plugin.invalid_invitation_message()]} == errors_on(changeset)
    end

    test "ensures registration is not possible with an expired code (invitation_required = true)", %{config: config, user: user} do
      code = "abcdefghijklmnopqrstuvwxyz"
      invitation_fixture(user, @bad_email, code: code, sent_at: config.invitation_within + 1)
      {:error, changeset} = to_changeset(code, @bad_email, config)

      refute changeset.valid?
      assert %{base: [@plugin.invitation_expired_message()]} == errors_on(changeset)
    end

    test "ensures registration is not possible with an already used invitation (invitation_required = true)", %{config: config, user: user} do
      code = "abcdefghijklmnopqrstuvwxyz"
      invitation_fixture(user, "012@345.678", code: code, accepted_by: user) # user accepted its own invitation but it can't happen in real world
      {:error, changeset} = to_changeset(code, @bad_email, config)

      refute changeset.valid?
      assert %{base: [@plugin.invalid_invitation_message()]} == errors_on(changeset)
    end

    test "ensures registration is possible with an invitation when required (invitation_required = true)", %{config: config} do
      assert catch_error(to_changeset(@code, @bad_email, %{config | email_matching_invitation: false}))
    end

    test "ensures registration is possible with an invitation when required and email address matches (invitation_required = true + email_matching_invitation = true)", %{config: config} do
      assert catch_error(to_changeset(@code, @email, %{config | email_matching_invitation: true}))
    end

    test "ensures registration is not possible with an invitation when required and email address does not match (invitation_required = true + email_matching_invitation = true)", %{config: config} do
      {:error, changeset} = to_changeset(@code, @bad_email, %{config | email_matching_invitation: true})

      refute changeset.valid?
      assert %{base: [@plugin.invitation_email_mismatch_message()]} == errors_on(changeset)
    end
  end
end
