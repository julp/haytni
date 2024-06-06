defmodule Haytni.AnonymizationPlugin.OnDeleteUserTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.AnonymizationPlugin,
  ]

  describe "Haytni.AnonymizationPlugin.on_delete_user/4 (callback)" do
    setup do
      user = user_fixture()

      binding()
    end

    test "ensures user's data are correctly anonymized", %{user: user} do
      new_firstname = "DELETED"
      new_lastname = &("account ##{&1.id} was deleted")
      config = @plugin.build_config(fields_to_reset_on_delete: [:email, :encrypted_password, firstname: new_firstname, lastname: new_lastname])
      multi = @plugin.on_delete_user(Ecto.Multi.new(), user, @stack, config)

      [update: {:update, changeset, []}] = Ecto.Multi.to_list(multi)

      assert {:ok, nil} == Ecto.Changeset.fetch_change(changeset, :email)
      assert {:ok, nil} == Ecto.Changeset.fetch_change(changeset, :encrypted_password)
      assert {:ok, new_firstname} == Ecto.Changeset.fetch_change(changeset, :firstname)
      {:ok, lastname} = Ecto.Changeset.fetch_change(changeset, :lastname)
      assert lastname == new_lastname.(user)

      @repo.transaction(multi)
      updated_user = Haytni.get_user(@stack, user.id)

      assert is_nil(updated_user.email)
      assert is_nil(updated_user.encrypted_password)
      assert new_firstname == updated_user.firstname
      assert new_lastname.(user) == updated_user.lastname
    end
  end
end
