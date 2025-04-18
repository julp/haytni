defmodule Haytni.Invitable.InvitationCreateControllerTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.InvitablePlugin,
  ]

  defp invitation_params(attrs \\ []) do
    [
      sent_to: "not a valid email address",
    ]
    |> Params.create(attrs)
    |> Params.wrap(:invitation)
  end

  @valid_params [sent_to: "abc.def@ghi"]
  describe "HaytniWeb.Invitable.InvitationController#create" do
    setup do
      [
        user: user_fixture(),
      ]
    end

    test "raises if there is no current user (not logged in)", %{conn: conn} do
      assert_raise Phoenix.ActionClauseError, ~r/no function clause/, fn ->
        get(conn, Routes.haytni_user_invitation_path(conn, :new), invitation_params(@valid_params))
      end
    end

    test "checks error on invalid params", %{conn: conn, user: user} do
      response =
        conn
        |> assign(:current_user, user)
        |> post(Routes.haytni_user_invitation_path(conn, :create), invitation_params())
        |> html_response(200)

      assert contains_text?(response, Haytni.TestHelpers.invalid_format_message())
    end

    test "checks successful invitaton creation", %{conn: conn, user: user} do
      new_conn =
        conn
        |> assign(:current_user, user)
        |> post(Routes.haytni_user_invitation_path(conn, :create), invitation_params(@valid_params))

      assert new_conn.halted
      assert Phoenix.ConnTest.redirected_to(new_conn) == Routes.haytni_user_invitation_path(conn, :new)
      assert Phoenix.Flash.get(new_conn.assigns.flash, :info) == HaytniWeb.Invitable.InvitationController.invitation_sent_message()
    end
  end
end
