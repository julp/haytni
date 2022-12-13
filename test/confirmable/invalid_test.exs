defmodule Haytni.Confirmable.InvalidTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.ConfirmablePlugin,
  ]

  describe "Haytni.ConfirmablePlugin.invalid?/3 (callback)" do
    test "ensures confirmed account is not invalid" do
      user = %HaytniTest.User{confirmed_at: Haytni.Helpers.now()}

      refute @plugin.invalid?(user, @stack, nil)
    end

    test "ensures unconfirmed account is invalid" do
      user = %HaytniTest.User{confirmed_at: nil}

      assert {:error, @plugin.pending_confirmation_message()} == @plugin.invalid?(user, @stack, nil)
    end
  end
end
