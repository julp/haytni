if false do
  defmodule Haytni.Invitable.InvitationIndexControllerTest do
    use HaytniWeb.ConnCase, async: true

    describe "HaytniWeb.Invitable.InvitationIndexControllerTest" do
      test "raises if there is no current user (not logged in)", %{conn: conn} do
        assert_raise Phoenix.ActionClauseError, ~R/no function clause/, fn ->
          get(conn, Routes.haytni_user_invitation_path(conn, :index), %{})
        end
      end

      test "ensures invitation are listed with a current user (logged in)", %{conn: conn} do
        user = user_fixture()
        invitation = invitation_fixture(user, "abc@def.ghi")

        new_conn = conn
        |> assign(:current_user, user)
        |> get(Routes.haytni_user_invitation_path(conn, :index), %{})

        assert contains_text?(html_response(new_conn, 200), invitation.sent_to)
      end
    end
  end
end
