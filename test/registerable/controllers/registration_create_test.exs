defmodule Haytni.Registerable.RegistrationCreateControllerTest do
  use HaytniWeb.ConnCase, async: true

  @email "i@am.nobody"
  defp registration_params(attrs \\ %{}) do
    [email: @email, password: "0123456789!ABCDEF!abcdef"]
    |> Params.create(attrs)
    |> Params.confirm(~W[email password]a)
    |> Params.wrap(:registration)
  end

  describe "HaytniWeb.Registerable.RegistrationController#create" do
    if false do
      test "checks error on invalid registration", %{conn: conn} do
        new_conn = post(conn, Routes.registration_path(conn, :create), registration_params(email: "", password: ""))
        response = html_response(new_conn, 200)
        assert String.contains?(response, "<form ")
        assert String.contains?(response, "action=\"#{Routes.registration_path(conn, :create)}\"")
        assert contains_text?(response, empty_message())
        assert contains_text?(response, invalid_message())
      end
    end

    test "checks successful registration", %{conn: conn} do
      assert [] == HaytniTest.Users.list_users()
      new_conn = post(conn, Routes.registration_path(conn, :create), registration_params())
      response = html_response(new_conn, 200)
      assert [user = %HaytniTest.User{email: @email}] = HaytniTest.Users.list_users()

      assert contains_formatted_text?(response, HaytniWeb.Registerable.RegistrationController.account_to_be_confirmed_message(user))
    end
  end
end
