defmodule Haytni.Trackable.OnSuccessfulAuthentificationTest do
  use HaytniWeb.ConnCase, async: true

  alias HaytniTest.User
  #alias Haytni.Connection

  defp list_connections do
    Haytni.Connection
    |> Haytni.repo().all()
  end

  describe "Haytni.TrackablePlugin.on_successful_authentification/3 (callback)" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "ensures *sign_in_at fields are updated and there is a new record in connections table", %{conn: conn, user: user = %User{id: id}} do
      assert [] == list_connections()

      {^conn, ^user, changes} = Haytni.TrackablePlugin.on_successful_authentification(conn, user, Keyword.new())

      assert contains(Keyword.keys(changes), ~W[last_sign_in_at current_sign_in_at]a)
      assert changes[:last_sign_in_at] == user.current_sign_in_at
      #assert changes[:assert current_sign_in_at] ~ Haytni.now()
      assert [%Haytni.Connection{user_id: ^id, ip: %Postgrex.INET{address: {127, 0, 0, 1}, netmask: 32}}] = list_connections()
    end
  end
end
