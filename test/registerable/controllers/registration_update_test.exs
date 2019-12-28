defmodule Haytni.Registerable.RegistrationUpdateControllerTest do
  use HaytniWeb.ConnCase, async: true

  defp registration_params(attrs) do
    [email: "", password: "", current_password: ""]
    |> Params.create(attrs)
    |> Params.confirm(~W[password]a)
    |> Params.wrap(:registration)
  end

  @password "azerty"
  describe "HaytniWeb.Registerable.RegistrationController#update" do
    setup do
      {:ok, user: user_fixture(password: @password)}
    end

    if false do
      test "checks error on invalid edition", %{conn: conn, user: user} do
        new_conn = patch(conn, Routes.registration_path(conn, :update), registration_params())
        response = html_response(new_conn, 200)
        assert String.contains?(response, "<form ")
        assert String.contains?(response, "action=\"#{Routes.registration_path(conn, :update)}\"")
        assert contains_text?(response, empty_message())
        assert contains_text?(response, invalid_message())
      end
    end

    test "checks successful edition", %{conn: conn, user: user} do
      new_password = "0123456789"

      new_conn = conn
      |> assign(:current_user, user)
      |> patch(Routes.registration_path(conn, :update), registration_params(email: user.email, password: new_password, current_password: @password))

      assert html_response(new_conn, 200)
      assert get_flash(new_conn, :info) == HaytniWeb.Registerable.RegistrationController.successful_edition_message()
      assert [updated_user] = HaytniTest.Users.list_users()
      assert updated_user.id == user.id
      assert HaytniTestWeb.Haytni.fetch_config(Haytni.AuthenticablePlugin).password_check_fun.(updated_user, new_password, [])
    end
  end
end
