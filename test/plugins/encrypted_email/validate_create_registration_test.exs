defmodule Haytni.EncryptedEmail.ValidateCreateRegistrationTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.EncryptedEmailPlugin,
  ]

  @email "sarah.croche@dummy.com"
  @fields ~W[email password]a
  @valid_params [
    email: @email,
    password: "0123456789",
  ]

  defp to_changeset(params, config) do
    %HaytniTest.User{}
    |> Ecto.Changeset.cast(params, @fields)
    |> @plugin.validate_create_registration(HaytniTestWeb.Haytni, config)
  end

  defp registration_params(attrs \\ %{}) do
    @valid_params
    |> Params.create(attrs)
    |> Params.confirm(@fields)
  end

  describe "Haytni.EncryptedEmailPlugin.validate_create_registration/3" do
    test "ensures a hashed version of the email address is present as change in the resulting changeset" do
      config = nil # unused/none
      changeset =
        registration_params()
        |> to_changeset(config)

      assert changeset.valid?
      {:ok, hashed_email} = Ecto.Changeset.fetch_change(changeset, :encrypted_email)
      assert hashed_email == Haytni.EncryptedEmailPlugin.hash_email(@email)
    end
  end
end
