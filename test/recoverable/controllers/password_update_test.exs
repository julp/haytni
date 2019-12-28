defmodule Haytni.Recoverable.PasswordUpdateControllerTest do
  use HaytniWeb.ConnCase, async: true

  defp change_params(token) do
    [reset_password_token: token, password: "H1b0lnc9c!ZPGTr9Itje"]
    |> Params.create()
    |> Params.confirm(~W[password]a)
    |> Params.wrap(:password)
  end

  describe "HaytniWeb.Recoverable.PasswordController#update" do
    test "checks error when editing password for an invalid (inexistent) token", %{conn: conn} do
      new_conn = patch(conn, Routes.password_path(conn, :update), change_params("not a match"))
      assert contains_text?(html_response(new_conn, 200), Haytni.RecoverablePlugin.invalid_token_message())
    end

    test "checks successful password change", %{conn: conn} do
      user = Haytni.RecoverablePlugin.build_config()
      |> Haytni.RecoverablePlugin.reset_password_attributes()
      |> user_fixture()

      new_conn = patch(conn, Routes.password_path(conn, :update), change_params(user.reset_password_token))
      assert contains_text?(html_response(new_conn, 200), HaytniWeb.Recoverable.PasswordController.password_changed_message())
    end
  end
end
