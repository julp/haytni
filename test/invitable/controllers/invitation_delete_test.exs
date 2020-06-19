if false do
  defmodule Haytni.Invitable.InvitationDeleteControllerTest do
    use HaytniWeb.ConnCase, async: true

    @spec conn_to_user_invitation_path(conn :: Plug.Conn.t, invitation :: Haytni.InvitablePlugin.invitation) :: Plug.Conn.t
    defp conn_to_user_invitation_path(conn, invitation) do
      delete(conn, Routes.haytni_user_invitation_path(conn, :delete, invitation), %{})
    end

    describe "HaytniWeb.Invitable.InvitationController#delete" do
      setup do
        user = user_fixture()

        {:ok, user: user, invitation: invitation_fixture(user, "abc.def@ghi")}
      end

      test "raises if there is no current user (not logged in)", %{conn: conn, invitation: invitation} do
        assert_raise Phoenix.ActionClauseError, ~R/no function clause/, fn ->
          conn_to_user_invitation_path(conn, invitation)
        end
      end

      test "checks successful revokation of existing invitation", %{conn: conn, user: user, invitation: invitation} do
        new_conn = conn
        |> assign(:current_user, user)
        |> conn_to_user_invitation_path(invitation)

        assert new_conn.halted
        assert Phoenix.ConnTest.redirected_to(new_conn) == Routes.haytni_user_invitation_path(conn, :index)
      end

      test "checks successful revokation of unexistant invitation", %{conn: conn, user: user} do
        invitation = Haytni.InvitablePlugin.build_and_assoc_invitation(user, code: user.email, sent_to: user.email, sent_at: Haytni.Helpers.now(), id: 0)

        new_conn = conn
        |> assign(:current_user, user)
        |> conn_to_user_invitation_path(invitation)

        assert new_conn.halted
        assert Phoenix.ConnTest.redirected_to(new_conn) == Routes.haytni_user_invitation_path(conn, :index)
      end
    end
  end
end
