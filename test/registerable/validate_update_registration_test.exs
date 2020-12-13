defmodule Haytni.Registerable.ValidateUpdateRegistrationTest do
  use Haytni.DataCase, async: true

  # cas :
  # - normalisation ? (espace + casse)
  # - email présent et valide **si** changement
  # - mot de passe présent et confirmé **si** changement

  @password "not a secret"
  defp registration_params(attrs) do
    [email: "", password: "", current_password: ""]
    |> Params.create(attrs)
    |> Params.confirm(~W[password]a)
  end

  defp to_changeset(params, user, config) do
    user
    |> Ecto.Changeset.cast(params, ~W[email password current_password]a)
    |> Haytni.RegisterablePlugin.validate_update_registration(HaytniTestWeb.Haytni, config)
  end

  describe "Haytni.RegisterablePlugin.validate_update_registration/3" do
    setup do
      {:ok, config: Haytni.RegisterablePlugin.build_config(), user: user_fixture(password: @password)}
    end

    test "ensures email presence", %{config: config, user: user} do
      changeset = registration_params(current_password: @password)
      |> to_changeset(user, config)

      refute changeset.valid?
      assert %{email: [empty_message()]} == errors_on(changeset)
    end

    test "ensures password confirmation", %{config: config, user: user} do
      changeset = registration_params(email: user.email, current_password: @password, password: "0123456789")
      |> Map.put("password_confirmation", "9876543210")
      |> to_changeset(user, config)

      refute changeset.valid?
      assert %{password_confirmation: [confirmation_mismatch_message()]} == errors_on(changeset)
    end

    test "ensures current password is requested on email change", %{config: config, user: user}  do
      changeset = registration_params(email: "new@mail.com")
      |> to_changeset(user, config)

      #{:error, output_changeset} = HaytniTest.Repo.update(changeset)
      refute changeset.valid?
      assert %{current_password: [empty_message()]} == errors_on(changeset)
    end

    test "ensures email change with current password", %{config: config, user: user}  do
      new_email = "new@mail.com"
      changeset = registration_params(email: new_email, current_password: @password)
      |> to_changeset(user, config)

      assert {:ok, updated_user} = HaytniTest.Repo.update(changeset)
      assert updated_user.email == new_email
    end

    test "ensures current password is requested on password change", %{config: config, user: user}  do
      # NOTE: even if you change the password, the (same) email has to be part of params
      changeset = registration_params(email: user.email, password: "0123456789")
      |> to_changeset(user, config)

      refute changeset.valid?
      assert %{current_password: [empty_message()]} == errors_on(changeset)
    end

    test "ensures password change with current password", %{config: config, user: user}  do
      new_password = "neither a secret"
      # NOTE: even if you change the password, the (same) email has to be part of params
      changeset = registration_params(email: user.email, password: new_password, current_password: @password)
      |> to_changeset(user, config)

      assert {:ok, updated_user} = HaytniTest.Repo.update(changeset)
      assert Haytni.AuthenticablePlugin.check_password(updated_user, new_password, Haytni.AuthenticablePlugin.build_config())
    end

    test "ensures email uniqueness", %{config: config, user: user} do
      other_user = user_fixture()
      input_changeset = registration_params(email: other_user.email, current_password: @password)
      |> to_changeset(user, config)

      # NOTE: unique_constraint will only pop up after a Repo.update
      {:error, output_changeset} = HaytniTest.Repo.update(input_changeset)
      refute output_changeset.valid?
      assert %{email: [already_took_message()]} == errors_on(output_changeset)
    end

    # stolen from validate_create_registration test
    test "ensures email format", %{config: config, user: user} do
      for email <- ~W[dummy.com] do
        changeset = registration_params(email: email, current_password: @password)
        |> to_changeset(user, config)

        refute changeset.valid?
        assert %{email: [invalid_format_message()]} == errors_on(changeset)
      end
    end
  end
end
