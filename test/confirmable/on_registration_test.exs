defmodule Haytni.Confirmable.OnRegistrationTest do
  use Haytni.DataCase, async: true
  use Bamboo.Test

  describe "Haytni.ConfirmablePlugin.on_registration/1" do
    test "a mail is sent at/after registration" do
      user = %HaytniTest.User{email: "abc@def.ghi", confirmation_token: "0123"}

      actions = Ecto.Multi.new()
      |> Haytni.ConfirmablePlugin.on_registration()
      |> Ecto.Multi.to_list()

      assert [{:send_confirmation_instructions, {:run, fun}}] = actions
      assert {:ok, :success} = fun.(Haytni.repo(), %{user: user})
      assert_delivered_email Haytni.ConfirmableEmail.confirmation_email(user)
    end
  end
end
