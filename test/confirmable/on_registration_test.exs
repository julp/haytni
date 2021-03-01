defmodule Haytni.Confirmable.OnRegistrationTest do
  use Haytni.DataCase, async: true
  use Bamboo.Test

  describe "Haytni.ConfirmablePlugin.on_registration/3" do
    test "a mail is sent at/after registration" do
      user = user_fixture(email: "abc@def.ghi")
      config = Haytni.ConfirmablePlugin.build_config()

      operations =
        Ecto.Multi.new()
        |> Haytni.ConfirmablePlugin.on_registration(HaytniTestWeb.Haytni, config)
        |> Ecto.Multi.to_list()

      state = %{user: user}
      assert [
        {:confirmation_token, {:run, fun1}},
        {:send_confirmation_instructions, {:run, fun2}}
      ] = operations

      assert {:ok, confirmation_token = %HaytniTest.UserToken{}} = fun1.(HaytniTest.Repo, state)
      assert confirmation_token.user_id == user.id
      assert confirmation_token.context == Haytni.ConfirmablePlugin.token_context(nil)
      assert is_binary(confirmation_token.token)

      state = Map.put(state, :confirmation_token, confirmation_token)
      assert {:ok, true} = fun2.(HaytniTest.Repo, state)
      assert_delivered_email Haytni.ConfirmableEmail.confirmation_email(user, Haytni.Token.url_encode(confirmation_token), HaytniTestWeb.Haytni, config)
    end
  end
end
