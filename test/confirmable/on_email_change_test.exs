defmodule Haytni.Confirmable.OnEmailChangeTest do
  use Haytni.DataCase, async: true
  use Bamboo.Test

  @new_email "123@456.789"
  @old_email "abc@def.ghi"
  describe "Haytni.ConfirmablePlugin.on_email_change/1" do
    test "ensures a notice is sent to old address and a new confirmation token is generated when email address is changed when reconfirmable is enabled" do
      user = %HaytniTest.User{email: @old_email}

      changeset = user
      |> Ecto.Changeset.change(email: @new_email)

      {multi, changeset} = Haytni.ConfirmablePlugin.on_email_change(Ecto.Multi.new(), changeset)

      {:ok, updated_user} = changeset
      |> apply_action(:update)

      assert [
        # <TODO: specific to reconfirmable>
        {:send_reconfirmation_instructions, {:run, fun1}},
        # </TODO: specific to reconfirmable>
        {:send_notice_about_email_change, {:run, fun2}}
      ] = Ecto.Multi.to_list(multi)

      # simulate Haytni.handle_email_change
      state = %{user: updated_user, old_email: @old_email, new_email: @new_email}
      # <TODO: specific to reconfirmable>
      assert {:ok, :success} = fun1.(Haytni.repo(), state)
      assert_delivered_email Haytni.ConfirmableEmail.reconfirmation_email(updated_user)
      # </TODO: specific to reconfirmable>

      assert {:ok, :success} = fun2.(Haytni.repo(), state)
      assert_delivered_email Haytni.ConfirmableEmail.email_changed(updated_user, @old_email)

      # <TODO: specific to reconfirmable>
      assert is_binary(Ecto.Changeset.get_change(changeset, :confirmation_token))
      assert @new_email == Ecto.Changeset.get_change(changeset, :unconfirmed_email)
      assert %DateTime{} = Ecto.Changeset.get_change(changeset, :confirmation_sent_at)

      assert is_binary(updated_user.confirmation_token)
      assert @new_email == updated_user.unconfirmed_email
      assert %DateTime{} = updated_user.confirmation_sent_at
      # </TODO: specific to reconfirmable>
    end
  end
end
