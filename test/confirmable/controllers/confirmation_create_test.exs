defmodule Haytni.Confirmable.ConfirmationCreateControllerTest do
  use HaytniWeb.ConnCase, async: true

  defp confirmation_params(user \\ %HaytniTest.User{}) do
    [
      email: "not a match",
      first_name: "not a match",
      last_name: "not a match",
    ]
    |> Params.create(user)
    |> Params.wrap(:confirmation)
  end

  @keys [
    ~W[email]a,
    #~W[first_name last_name]a, # NOTE: to work we'd need to override HatyniTestWeb.Haytni plugins_with_config/0
  ]

  describe "HaytniWeb.Confirmable.ConfirmationController#create" do
    for keys <- @keys do
      imploded_keys = Enum.join(keys, ", ")

      test "checks error on invalid confirmation request with #{imploded_keys} as key(s)", %{conn: conn} do
        response =
          conn
          |> post(Routes.haytni_user_confirmation_path(conn, :create), confirmation_params())
          |> html_response(200)

        assert contains_text?(response, Haytni.Helpers.no_match_message())
      end

      test "checks error for requesting a confirmation request to an already confirmed account with #{imploded_keys} as key(s)", %{conn: conn} do
        user = user_fixture(email: "parker.peter@daily-bugle.com", first_name: "Peter", last_name: "Parker", confirmed_at: Haytni.Helpers.now())

        response =
          conn
          |> post(Routes.haytni_user_confirmation_path(conn, :create), confirmation_params(user))
          |> html_response(200)

        assert contains_text?(response, Haytni.ConfirmablePlugin.alreay_confirmed_message())
      end

      test "checks successful resending confirmation request with #{imploded_keys} as key(s)", %{conn: conn} do
        user = user_fixture(email: "parker.peter@daily-bugle.com", first_name: "Peter", last_name: "Parker")

        response =
          conn
          |> post(Routes.haytni_user_confirmation_path(conn, :create), confirmation_params(user))
          |> html_response(200)

        assert contains_formatted_text?(response, HaytniWeb.Confirmable.ConfirmationController.confirmation_sent_message())
      end
    end
  end
end
