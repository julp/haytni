defmodule Haytni.Confirmable.OnEmailChangeTest do
  use Haytni.DataCase, async: true
  use Bamboo.Test

  @new_email "123@456.789"
  @old_email "abc@def.ghi"
  describe "Haytni.ConfirmablePlugin.on_email_change/4" do
    setup do
      [
        config: Haytni.ConfirmablePlugin.build_config(),
      ]
    end

    test "ensures email is changed and a notice is sent to old address when reconfirmable = false", %{config: config} do
      config = %{config | reconfirmable: false}
      user = %HaytniTest.User{email: @old_email}

      changeset = Ecto.Changeset.change(user, email: @new_email)

      {multi, changeset} = Haytni.ConfirmablePlugin.on_email_change(Ecto.Multi.new(), changeset, HaytniTestWeb.Haytni, config)

      {:ok, updated_user} = Ecto.Changeset.apply_action(changeset, :update)

      assert [{:send_notice_about_email_change, {:run, fun}}] = Ecto.Multi.to_list(multi)

      # simulates Haytni.handle_email_change
      state = %{user: updated_user, old_email: @old_email, new_email: @new_email}

      assert {:ok, :success} = fun.(HaytniTest.Repo, state)
      assert_delivered_email Haytni.ConfirmableEmail.email_changed(updated_user, @old_email, HaytniTestWeb.Haytni, config)

      assert @new_email == Ecto.Changeset.get_change(changeset, :email)
      assert @new_email == updated_user.email
    end

    test "ensures email is not changed + a notice is sent to old address + a new confirmation token is generated then sent to new email address when reconfirmable = true", %{config: config} do
      config = %{config | reconfirmable: true}
      user = %HaytniTest.User{email: @old_email}

      changeset = Ecto.Changeset.change(user, email: @new_email)

      {multi, changeset} = Haytni.ConfirmablePlugin.on_email_change(Ecto.Multi.new(), changeset, HaytniTestWeb.Haytni, config)

      {:ok, updated_user} = Ecto.Changeset.apply_action(changeset, :update)

      assert [
        {:send_reconfirmation_instructions, {:run, fun1}},
        {:send_notice_about_email_change, {:run, fun2}}
      ] = Ecto.Multi.to_list(multi)

      # simulates Haytni.handle_email_change
      state = %{user: updated_user, old_email: @old_email, new_email: @new_email}

      assert {:ok, :success} = fun1.(HaytniTest.Repo, state)
      assert_delivered_email Haytni.ConfirmableEmail.reconfirmation_email(updated_user, updated_user.unconfirmed_email, updated_user.confirmation_token, HaytniTestWeb.Haytni, config)

      assert {:ok, :success} = fun2.(HaytniTest.Repo, state)
      assert_delivered_email Haytni.ConfirmableEmail.email_changed(updated_user, @old_email, HaytniTestWeb.Haytni, config)

      assert is_binary(Ecto.Changeset.get_change(changeset, :confirmation_token))
      assert @new_email == Ecto.Changeset.get_change(changeset, :unconfirmed_email)
      assert %DateTime{} = Ecto.Changeset.get_change(changeset, :confirmation_sent_at)

      assert is_binary(updated_user.confirmation_token)
      assert @new_email == updated_user.unconfirmed_email
      assert %DateTime{} = updated_user.confirmation_sent_at
    end
  end
end
