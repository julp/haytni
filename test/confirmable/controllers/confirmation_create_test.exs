defmodule Haytni.Confirmable.ConfirmationCreateControllerTest do
  use HaytniWeb.ConnCase, async: true

  defp confirmation_params(user \\ %HaytniTest.User{}) do
    [email: "not a match", first_name: "not a match", last_name: "not a match"]
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

      test "checks error on invalid reconfirmation request with #{imploded_keys} as key(s)", %{conn: conn} do
        new_conn = post(conn, Routes.haytni_user_confirmation_path(conn, :create), confirmation_params())
        assert contains_text?(html_response(new_conn, 200), Haytni.Helpers.no_match_message())
      end

      test "checks successful reconfirmation request with #{imploded_keys} as key(s)", %{conn: conn} do
        user = Haytni.ConfirmablePlugin.build_config(confirmation_keys: unquote(keys))
        |> Haytni.ConfirmablePlugin.new_confirmation_attributes()
        |> Keyword.merge(email: "parker.peter@daily-bugle.com", first_name: "Peter", last_name: "Parker")
        |> user_fixture()

        new_conn = post(conn, Routes.haytni_user_confirmation_path(conn, :create), confirmation_params(user))
        assert contains_formatted_text?(html_response(new_conn, 200), HaytniWeb.Confirmable.ConfirmationController.confirmation_sent_message())
      end
    end
  end
end
