defmodule Haytni.Registerable.UpdatePasswordTest do
  use Haytni.DataCase, async: true

  defp password_attrs(password)
    when is_binary(password)
  do
    [
      password: password,
    ]
    |> Params.create()
    |> Params.confirm(~W[password]a)
  end

  @new_password "h1myZPGd6bC2"
  @current_password "u3htaBvZQlFq"
  describe "Haytni.RegisterablePlugin.update_password/4" do
    setup do
      [
        user: user_fixture(password: @current_password),
        module: HaytniTestWeb.Haytni,
        #plugin: Haytni.RegisterablePlugin,
        config: Haytni.RegisterablePlugin.build_config(),
      ]
    end

    test "ensures password can't be empty", %{module: module, config: _config, user: user} do
      {:error, changeset = %Ecto.Changeset{}} = Haytni.RegisterablePlugin.update_password(module, user, @current_password, password_attrs(""))

      refute changeset.valid?
      assert %{password: [empty_message()]} == errors_on(changeset)
    end

    test "ensures password confirmation matches", %{module: module, config: _config, user: user} do
      attrs =
        @new_password
        |> password_attrs()
        |> Map.replace!("password_confirmation", String.reverse(@new_password))

      {:error, changeset = %Ecto.Changeset{}} = Haytni.RegisterablePlugin.update_password(module, user, @current_password, attrs)

      refute changeset.valid?
      assert %{password_confirmation: [confirmation_mismatch_message()]} == errors_on(changeset)
    end

    test "ensures current password is requested on password change", %{module: module, config: _config, user: user}  do
      {:error, changeset = %Ecto.Changeset{}} = Haytni.RegisterablePlugin.update_password(module, user, "not the password", password_attrs(@new_password))

      refute changeset.valid?
      assert %{current_password: [Haytni.RegisterablePlugin.invalid_current_password_message()]} == errors_on(changeset)
    end

    test "ensures password change with current password", %{module: module, config: _config, user: user}  do
      {:ok, updated_user} = Haytni.RegisterablePlugin.update_password(module, user, @current_password, password_attrs(@new_password))

      assert String.starts_with?(updated_user.encrypted_password, "$2b$04$")
      assert Haytni.AuthenticablePlugin.valid_password?(updated_user, @new_password, HaytniTestWeb.Haytni.fetch_config(Haytni.AuthenticablePlugin))
    end
  end
end
