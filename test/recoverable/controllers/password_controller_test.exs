defmodule Haytni.Recoverable.PasswordControllerTest do
  use HaytniWeb.ConnCase, async: true

  defp change_params(token) do
    [
      reset_password_token: token,
      password: "H1b0lnc9c!ZPGTr9Itje",
    ]
    |> Params.create()
    |> Params.confirm(~W[password]a)
    |> Params.wrap(:password)
  end

  defp recover_params(user \\ %HaytniTest.User{}) do
    [
      email: "not a match",
      first_name: "not a match",
      last_name: "not a match",
    ]
    |> Params.create(user)
    |> Params.wrap(:password)
  end

  @keys [
    ~W[email]a,
    #~W[first_name last_name]a, # NOTE: to work we'd need to override HatyniTestWeb.Haytni plugins_with_config/0
  ]

  defp maybe_succeed(conn, params) do
    response =
      conn
      |> post(Routes.haytni_user_password_path(conn, :create), params)
      |> html_response(200)

    assert contains_formatted_text?(response, HaytniWeb.Recoverable.PasswordController.recovery_token_sent_message())
  end

  describe "HaytniWeb.Recoverable.PasswordController#create" do
    for keys <- @keys do
      test "checks error on invalid password recovery request with #{inspect(keys)} as key(s)", %{conn: conn} do
        maybe_succeed(conn, recover_params())
      end

      test "checks successful password recovery request with #{inspect(keys)} as key(s)", %{conn: conn} do
        user =
          [
            email: "parker.peter@daily-bugle.com",
            first_name: "Peter",
            last_name: "Parker",
          ]
          |> user_fixture()

        maybe_succeed(conn, recover_params(user))
      end
    end
  end

  defp check_form_presence(response) do
    assert response =~ "name=\"password[password]\""
  end

  describe "HaytniWeb.Recoverable.PasswordController#edit" do
    test "renders form for editing password", %{conn: conn} do
      conn
      |> get(Routes.haytni_user_password_path(conn, :edit), %{"reset_password_token" => "nevermind"})
      |> html_response(200)
      |> check_form_presence()
    end
  end

  describe "HaytniWeb.Recoverable.PasswordController#update" do
    test "checks error when editing password for an invalid (inexistent) token", %{conn: conn} do
      response =
        conn
        |> patch(Routes.haytni_user_password_path(conn, :update), change_params("not a match"))
        |> html_response(200)

      check_form_presence(response)
      assert contains_text?(response, Haytni.RecoverablePlugin.invalid_token_message())
    end

    test "checks successful password change", %{conn: conn} do
      user = user_fixture()
      token =
        user
        |> token_fixture(Haytni.RecoverablePlugin)
        |> Haytni.Token.url_encode()

      response =
        conn
        |> patch(Routes.haytni_user_password_path(conn, :update), change_params(token))
        |> html_response(200)

      assert contains_text?(response, HaytniWeb.Recoverable.PasswordController.password_changed_message())
    end
  end
end
