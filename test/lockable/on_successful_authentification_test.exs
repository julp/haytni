defmodule Haytni.Lockable.OnSuccessfulAuthentificationTest do
  use HaytniWeb.ConnCase, async: true

  alias HaytniTest.User

  # REMINDER: the on_successful_authentification callback is not made to check the validity of the user,
  # just to do something when a valid (validity was ensured prior on_successful_authentification call)
  # user successfully authenticate himself
  describe "Haytni.LockablePlugin.on_successful_authentification/3 (callback)" do
    test "ensures failed attempts are cleared after successful authentification", %{conn: conn} do
      [
        %User{id: 123, failed_attempts: 0},
        %User{id: 456, failed_attempts: 1},
        %User{id: 789, failed_attempts: 100},
      ]
      |> Enum.each(
        fn user = %User{id: id} ->
          assert {%Plug.Conn{}, %User{id: ^id}, [failed_attempts: 0]} = Haytni.LockablePlugin.on_successful_authentification(conn, user, Keyword.new())
        end
      )
    end
  end
end
