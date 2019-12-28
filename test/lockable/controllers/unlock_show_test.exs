defmodule Haytni.Lockable.UnlockShowControllerTest do
  use HaytniWeb.ConnCase, async: true

  describe "HaytniWeb.Lockable.UnlockController#show" do
    test "checks error on invalid token", %{conn: conn} do
      new_conn = get(conn, Routes.unlock_path(conn, :show), %{"unlock_token" => "not a match"})
      assert contains_text?(html_response(new_conn, 200), Haytni.LockablePlugin.invalid_token_message())
    end

    test "checks successful unlocking", %{conn: conn} do
      user = Haytni.LockablePlugin.build_config()
      |> Haytni.LockablePlugin.lock_attributes()
      |> user_fixture()

      new_conn = get(conn, Routes.unlock_path(conn, :show), %{"unlock_token" => user.unlock_token})
      assert contains_text?(html_response(new_conn, 200), HaytniWeb.Lockable.UnlockController.unlock_message())
    end
  end
end
