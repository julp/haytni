defmodule Haytni.Lockable.UnlockControllerTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.LockablePlugin,
  ]

  @spec check_for_new_form(response :: String.t) :: true | no_return
  defp check_for_new_form(response) do
    assert response =~ "name=\"unlock[email]\""
  end

  @spec unlock_params(user :: Haytni.user) :: Haytni.params
  defp unlock_params(user \\ %HaytniTest.User{}) do
    [
      email: "not a match",
      first_name: "not a match",
      last_name: "not a match",
    ]
    |> Params.create(user)
    |> Params.wrap(:unlock)
  end

  @keys [
    ~W[email]a,
    #~W[first_name last_name]a, # NOTE: to work we'd need to override HatyniTestWeb.Haytni plugins_with_config/0
  ]

  describe "HaytniWeb.Lockable.UnlockController#show" do
    test "checks error on invalid token", %{conn: conn} do
      response =
        conn
        |> get(Routes.haytni_user_unlock_path(conn, :show), %{"unlock_token" => "not a match"})
        |> html_response(200)

      assert contains_text?(response, @plugin.invalid_token_message())
    end

    test "checks successful unlocking", %{conn: conn} do
      user =
        @plugin.lock_attributes()
        |> user_fixture()
      unlock_token =
        user
        |> token_fixture(@plugin)
        |> Haytni.Token.url_encode()

      response =
        conn
        |> get(Routes.haytni_user_unlock_path(conn, :show), %{"unlock_token" => unlock_token})
        |> html_response(200)

      assert contains_text?(response, HaytniWeb.Lockable.UnlockController.unlock_message())
    end
  end

  describe "HaytniWeb.Lockable.UnlockController#new" do
    test "renders form for requesting a new unlock token", %{conn: conn} do
      conn
      |> get(Routes.haytni_user_unlock_path(conn, :new))
      |> html_response(200)
      |> check_for_new_form()
    end
  end

  defp maybe_succeed(conn, params) do
    response =
      conn
      |> post(Routes.haytni_user_unlock_path(conn, :create), params)
      |> html_response(200)

    assert contains_formatted_text?(response, HaytniWeb.Lockable.UnlockController.new_token_sent_message())
  end

  describe "HaytniWeb.Lockable.UnlockController#create" do
    for keys <- @keys do
      test "checks error on invalid unlock request with #{inspect(keys)} as key(s)", %{conn: conn} do
        maybe_succeed(conn, unlock_params())
      end

      test "checks successful unlock request with #{inspect(keys)} as key(s)", %{conn: conn} do
        user =
          @plugin.lock_attributes()
          |> Keyword.merge(email: "parker.peter@daily-bugle.com", first_name: "Peter", last_name: "Parker")
          |> user_fixture()

        maybe_succeed(conn, unlock_params(user))
      end
    end
  end
end
