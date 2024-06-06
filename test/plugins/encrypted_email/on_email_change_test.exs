defmodule Haytni.EncryptedEmailPlugin.OnEmailChangeTest do
  use Haytni.DataCase, [
    email: true,
    plugin: Haytni.EncryptedEmailPlugin,
  ]

  @new_email "123@456.789"
  @old_email "abc@def.ghi"
  describe "Haytni.EncryptedEmailPlugin.on_email_change/4" do
    test "ensures email's hash is changed" do
      config = nil # unused/none
      user = %HaytniTest.User{email: @old_email}

      changeset = Ecto.Changeset.change(user, email: @new_email)
      {multi, changeset} = @plugin.on_email_change(Ecto.Multi.new(), changeset, @stack, config)

      assert [] = Ecto.Multi.to_list(multi)
      assert {:ok, Haytni.EncryptedEmailPlugin.hash_email(@new_email)} == Ecto.Changeset.fetch_change(changeset, :encrypted_email)
    end
  end
end
