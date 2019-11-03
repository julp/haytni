defmodule Haytni.Confirmable.InvalidTest do
  use HaytniWeb.ConnCase, async: true

  describe "Haytni.ConfirmablePlugin.invalid?/1 (callback)" do
    test "ensures confirmed account is not invalid" do
      user = %HaytniTest.User{confirmed_at: Haytni.now()}

      refute Haytni.ConfirmablePlugin.invalid?(user)
    end

    test "ensures unconfirmed account is invalid" do
      user = %HaytniTest.User{confirmed_at: nil}

      assert {:error, reason} = Haytni.ConfirmablePlugin.invalid?(user)
      assert reason =~ ~R/check your emails/i
    end
  end
end
