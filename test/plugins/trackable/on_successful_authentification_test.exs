defmodule Haytni.Trackable.OnSuccessfulAuthentificationTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.TrackablePlugin,
  ]

  alias HaytniTest.User

  @loopback (if @repo.__adapter__() == Ecto.Adapters.Postgres do
    %Postgrex.INET{address: {127, 0, 0, 1}, netmask: 32}
  else
    "127.0.0.1"
  end)

  describe "Haytni.TrackablePlugin.on_successful_authentication/6 (callback)" do
    setup do
      [
        user: user_fixture(),
      ]
    end

    test "ensures there is a new record in connections table", %{conn: conn, user: user = %User{id: id}} do
      assert [] == list_connections(@repo, user)

      {^conn, multi, _changes} = @plugin.on_successful_authentication(conn, user, Ecto.Multi.new(), Keyword.new(), @stack, nil)

      assert [connection: {:insert, %Ecto.Changeset{}, []}] = Ecto.Multi.to_list(multi)
      #assert ip in changes?

      @repo.transaction(multi)
      assert [%HaytniTest.UserConnection{user_id: ^id, ip: @loopback}] = list_connections(@repo, user)
    end
  end
end
