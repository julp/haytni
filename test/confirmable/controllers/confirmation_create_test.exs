defmodule Haytni.Confirmable.ConfirmationCreateControllerTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.ConfirmablePlugin,
  ]

  defp confirmation_params(enumerable \\ []) do
    enumerable
    |> Params.create()
    |> Params.wrap(:confirmation)
  end

  @keys [
    ~W[email]a,
    #~W[first_name last_name]a, # NOTE: to work we'd need to override HatyniTestWeb.Haytni plugins_with_config/0
  ]

  defp maybe_succeed(conn, keys, params) do
    response =
      conn
      |> post(Routes.haytni_user_confirmation_path(conn, :create), params)
      |> html_response(200)

    for key <- keys do
      refute response =~ "name=\"confirmation[#{key}]\""
    end
    assert contains_formatted_text?(response, HaytniWeb.Confirmable.ConfirmationController.confirmation_sent_message())
  end

  describe "HaytniWeb.Confirmable.ConfirmationController#create" do
    for keys <- @keys do
      test "checks errors on invalid request with #{inspect(keys)} as key(s)", %{conn: conn} do
        response =
          conn
          |> post(Routes.haytni_user_confirmation_path(conn, :create), confirmation_params())
          |> html_response(200)

        for key <- unquote(keys) do
          assert response =~ "name=\"confirmation[#{key}]\""
        end
      end

      test "checks faking resending confirmation on invalid request with #{inspect(keys)} as key(s)", %{conn: conn} do
        params =
          [
            email: "not a match",
            first_name: "not a match",
            last_name: "not a match",
          ]
          |> confirmation_params()

        maybe_succeed(conn, unquote(keys), params)
      end

      test "checks faking resending confirmation request to an already confirmed account with #{inspect(keys)} as key(s)", %{conn: conn} do
        params =
          [
            first_name: "Peter",
            last_name: "Parker",
            confirmed_at: Haytni.Helpers.now(),
            email: "parker.peter@daily-bugle.com",
          ]
          |> user_fixture()
          |> confirmation_params()

        maybe_succeed(conn, unquote(keys), params)
      end

      test "checks successful resending confirmation request with #{inspect(keys)} as key(s)", %{conn: conn} do
        params =
          [
            first_name: "Peter",
            last_name: "Parker",
            email: "parker.peter@daily-bugle.com",
          ]
          |> user_fixture()
          |> confirmation_params()

        maybe_succeed(conn, unquote(keys), params)
      end
    end
  end
end
