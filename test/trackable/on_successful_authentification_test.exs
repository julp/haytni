defmodule Haytni.Trackable.OnSuccessfulAuthentificationTest do
  use HaytniWeb.ConnCase, async: true

  alias HaytniTest.User

  defp list_connections do
    HaytniTest.UserConnection
    |> HaytniTest.Repo.all()
  end

  @loopback (if HaytniTest.Repo.__adapter__() == Ecto.Adapters.Postgres do
    %Postgrex.INET{address: {127, 0, 0, 1}, netmask: 32}
  else
    "127.0.0.1"
  end)

  describe "Haytni.TrackablePlugin.on_successful_authentication/6 (callback)" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "ensures *sign_in_at fields are updated and there is a new record in connections table", %{conn: conn, user: user = %User{id: id}} do
      assert [] == list_connections()

      {^conn, multi, changes} = Haytni.TrackablePlugin.on_successful_authentication(conn, user, Ecto.Multi.new(), Keyword.new(), HaytniTestWeb.Haytni, nil)

      assert [connection: {:insert, changeset = %Ecto.Changeset{}, []}] = Ecto.Multi.to_list(multi)
      #assert ip in changes?

      assert contains?(Keyword.keys(changes), ~W[last_sign_in_at current_sign_in_at]a)
      assert changes[:last_sign_in_at] == user.current_sign_in_at
      #assert changes[:assert current_sign_in_at] ~ Haytni.Helpers.now()

      HaytniTest.Repo.transaction(multi)
      assert [%HaytniTest.UserConnection{user_id: ^id, ip: @loopback}] = list_connections()
    end
  end
end
