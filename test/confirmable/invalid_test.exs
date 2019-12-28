defmodule Haytni.Confirmable.InvalidTest do
  use HaytniWeb.ConnCase, async: true

  describe "Haytni.ConfirmablePlugin.invalid?/2 (callback)" do
    test "ensures confirmed account is not invalid" do
      user = %HaytniTest.User{confirmed_at: Haytni.Helpers.now()}

      refute Haytni.ConfirmablePlugin.invalid?(user, nil)
    end

    test "ensures unconfirmed account is invalid" do
      user = %HaytniTest.User{confirmed_at: nil}

      assert {:error, Haytni.ConfirmablePlugin.pending_confirmation_message()} == Haytni.ConfirmablePlugin.invalid?(user, nil)
    end
  end
end
