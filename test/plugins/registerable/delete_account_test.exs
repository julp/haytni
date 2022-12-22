defmodule Haytni.Registerable.DeleteAccountTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RegisterablePlugin,
  ]

  defp deletion_attrs(accept_deletion) do
    [
      accept_deletion: accept_deletion,
    ]
    |> Params.create()
  end

  @current_password "0123456789"
  describe "Haytni.RegisterablePlugin.delete_account/5" do
    setup do
      [
        user: user_fixture(password: @current_password),
        config: @plugin.build_config(with_delete: true),
      ]
    end

    test "ensures deletion occurs with correct password", %{config: config, user: user}  do
      {:ok, %{}} = @plugin.delete_account(@stack, config, user, @current_password, deletion_attrs(true))
    end

    test "ensures acceptance is requested for deletion", %{config: config, user: user}  do
      {:error, :validation_failed, changeset = %Ecto.Changeset{}, _changes_so_far} = @plugin.delete_account(@stack, config, user, @current_password, deletion_attrs(false))

      refute changeset.valid?
      assert %{accept_deletion: [acceptance_required_message()]} == errors_on(changeset)
    end

    test "ensures current password is requested for deletion", %{config: config, user: user}  do
      {:error, :validation_failed, changeset = %Ecto.Changeset{}, _changes_so_far} = @plugin.delete_account(@stack, config, user, "not the current password", deletion_attrs(true))

      refute changeset.valid?
      assert %{current_password: [@plugin.invalid_current_password_message()]} == errors_on(changeset)
    end

    test "ensures error without current password", %{config: config, user: user}  do
      {:error, :validation_failed, changeset = %Ecto.Changeset{}, _changes_so_far} = @plugin.delete_account(@stack, config, user, "", deletion_attrs(true))

      refute changeset.valid?
      assert %{current_password: [@plugin.invalid_current_password_message()]} == errors_on(changeset)
    end
  end
end
