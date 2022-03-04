defmodule Haytni.Authenticable.ValidateCreateRegistrationTest do
  use Haytni.DataCase, async: true

  alias HaytniTest.User

  # REMINDER: Haytni.AuthenticablePlugin is not responsible of validations (password length for example),
  # this is the responsability of Haytni.RegisterablePlugin
  @password "1234"
  describe "Haytni.AuthenticablePlugin.validate_create_registration/3" do
    setup do
      [
        config: HaytniTestWeb.Haytni.fetch_config(Haytni.AuthenticablePlugin),
      ]
    end

    test "ensures password is hashed (bcrypt) on registration (encrypted_password field populated)", %{config: config} do
      changeset =
        %User{}
        |> Ecto.Changeset.change(password: @password)
        |> Haytni.AuthenticablePlugin.validate_create_registration(HaytniTestWeb.Haytni, config)

      assert changeset.valid?
      assert String.starts_with?(Ecto.Changeset.get_change(changeset, :encrypted_password), "$2b$")
      assert Haytni.AuthenticablePlugin.valid_password?(Ecto.Changeset.apply_changes(changeset), @password, config)
    end
  end
end
