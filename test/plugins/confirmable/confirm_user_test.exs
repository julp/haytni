defmodule Haytni.Confirmable.ConfirmUserTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.ConfirmablePlugin,
  ]

  describe "Haytni.ConfirmablePlugin.confirm_user/2" do
    test "an unconfirmed user gets confirmed" do
      user = user_fixture(confirmed_at: nil)
      assert is_nil(user.confirmed_at)

      {:ok, updated_user} = @plugin.confirm_user(@stack, user)
      %DateTime{} = updated_user.confirmed_at
    end

    test "a confirmed user stays confirmed" do
      user = user_fixture(confirmed_at: Haytni.Helpers.now())
      %DateTime{} = user.confirmed_at

      {:ok, updated_user} = @plugin.confirm_user(@stack, user)
      # NOTE: confirmed_at is overwritten with current datetime
      %DateTime{} = updated_user.confirmed_at
    end
  end
end
