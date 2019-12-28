defmodule Haytni.Lockable.OnSuccessfulAuthentificationTest do
  use HaytniWeb.ConnCase, async: true

  alias HaytniTest.User

  # REMINDER: the on_successful_authentication callback is not made to check the validity of the user,
  # just to do something when a valid (validity was ensured prior on_successful_authentication call)
  # user successfully authenticate himself
  describe "Haytni.LockablePlugin.on_successful_authentication/5 (callback)" do
    test "ensures failed attempts are cleared after successful authentication", %{conn: conn} do
      config = Haytni.LockablePlugin.build_config()

      [
        %User{id: 123, failed_attempts: 0},
        %User{id: 456, failed_attempts: 1},
        %User{id: 789, failed_attempts: 100},
      ]
      |> Enum.each(
        fn user ->
          assert {%Plug.Conn{}, multi, [failed_attempts: 0]} = Haytni.LockablePlugin.on_successful_authentication(conn, user, Ecto.Multi.new(), Keyword.new(), config)
          assert [] == Ecto.Multi.to_list(multi)
        end
      )
    end
  end
end
