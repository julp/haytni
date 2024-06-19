defmodule Haytni.LastSeen.OnSuccessfulAuthentificationTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.LastSeenPlugin,
  ]

  describe "Haytni.LastSeenPlugin.on_successful_authentication/6 (callback)" do
    setup do
      [
        user: user_fixture(),
      ]
    end

    test "ensures *sign_in_at fields are updated", %{conn: conn, user: user} do
      {^conn, _multi, changes} = @plugin.on_successful_authentication(conn, user, Ecto.Multi.new(), Keyword.new(), @stack, nil)

      assert contains?(Keyword.keys(changes), ~W[last_sign_in_at current_sign_in_at]a)
      assert changes[:last_sign_in_at] == user.current_sign_in_at
      #assert changes[:assert current_sign_in_at] ~ Haytni.Helpers.now()
    end
  end
end
