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
      assert {:ok, @new_email} == Ecto.Changeset.fetch_change(changeset, :email)

      assert [{:send_notice_about_email_change, {:run, fun}}] = Ecto.Multi.to_list(multi)

      # simulates Haytni.handle_email_change
      state = %{user: user, old_email: @old_email, new_email: @new_email}

      assert {:ok, true} = fun.(HaytniTest.Repo, state)
      user
      |> Haytni.ConfirmableEmail.email_changed(@old_email, HaytniTestWeb.Haytni, config)
      |> assert_email_was_sent()
    end

    test "ensures email is not changed + a notice is sent to old address + a new confirmation token is generated then sent to new email address when reconfirmable = true", %{config: config} do
      config = %{config | reconfirmable: true}
      user = user_fixture(email: @old_email)

      changeset = Ecto.Changeset.change(user, email: @new_email)
      {multi, changeset} = Haytni.ConfirmablePlugin.on_email_change(Ecto.Multi.new(), changeset, HaytniTestWeb.Haytni, config)
      assert :error == Ecto.Changeset.fetch_change(changeset, :email)

      assert [
        {:confirmation_token, {:run, fun1}},
        {:send_reconfirmation_instructions, {:run, fun2}},
        {:send_notice_about_email_change, {:run, fun3}}
      ] = Ecto.Multi.to_list(multi)

      # simulates Haytni.handle_email_change
      state = %{user: user, old_email: @old_email, new_email: @new_email}

      #assert [] == HaytniTest.Repo.all(Haytni.Token.tokens_from_user_query(user, Haytni.ConfirmablePlugin.token_context(nil)))
      assert {:ok, confirmation_token = %HaytniTest.UserToken{}} = fun1.(HaytniTest.Repo, state)
      assert confirmation_token.user_id == user.id
      assert confirmation_token.context == Haytni.ConfirmablePlugin.token_context(@old_email)
      assert is_binary(confirmation_token.token)
      #assert [%HaytniTest.UserToken{^id: ^confirmation_token.id}] == HaytniTest.Repo.all(Haytni.Token.tokens_from_user_query(user, Haytni.ConfirmablePlugin.token_context(nil)))

      state = Map.put(state, :confirmation_token, confirmation_token)
      assert {:ok, true} = fun2.(HaytniTest.Repo, state)
      user
      |> Haytni.ConfirmableEmail.reconfirmation_email(@new_email, Haytni.Token.url_encode(confirmation_token), HaytniTestWeb.Haytni, config)
      |> assert_email_was_sent()

      assert {:ok, true} = fun3.(HaytniTest.Repo, state)
      user
      |> Haytni.ConfirmableEmail.email_changed(@old_email, HaytniTestWeb.Haytni, config)
      |> assert_email_was_sent()
    end
  end
end
