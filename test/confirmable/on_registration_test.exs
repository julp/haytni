defmodule Haytni.Confirmable.OnRegistrationTest do
  use Haytni.DataCase, async: true
  use Bamboo.Test

  describe "Haytni.ConfirmablePlugin.on_registration/3" do
    test "a mail is sent at/after registration" do
      config = Haytni.ConfirmablePlugin.build_config()
      user = %HaytniTest.User{email: "abc@def.ghi", confirmation_token: "0123"}

      actions =
        Ecto.Multi.new()
        |> Haytni.ConfirmablePlugin.on_registration(HaytniTestWeb.Haytni, config)
        |> Ecto.Multi.to_list()

      assert [{:send_confirmation_instructions, {:run, fun}}] = actions
      assert {:ok, :success} = fun.(HaytniTest.Repo, %{user: user})
      assert_delivered_email Haytni.ConfirmableEmail.confirmation_email(user, user.confirmation_token, HaytniTestWeb.Haytni, config)
    end
  end
end
