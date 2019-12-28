defmodule Haytni.Recoverable.PasswordCreateControllerTest do
  use HaytniWeb.ConnCase, async: true

  defp recover_params(user \\ %HaytniTest.User{}) do
    [email: "not a match", first_name: "not a match", last_name: "not a match"]
    |> Params.create(user)
    |> Params.wrap(:password)
  end

  @keys [
    ~W[email]a,
    #~W[first_name last_name]a, # NOTE: to work we'd need to override HatyniTestWeb.Haytni plugins_with_config/0
  ]

  describe "HaytniWeb.Recoverable.PasswordController#create" do
    for keys <- @keys do
      imploded_keys = Enum.join(keys, ", ")

      test "checks error on invalid password recovery request with #{imploded_keys} as key(s)", %{conn: conn} do
        new_conn = post(conn, Routes.password_path(conn, :create), recover_params())
        assert contains_text?(html_response(new_conn, 200), Haytni.Helpers.no_match_message())
      end

      test "checks successful password recovery request with #{imploded_keys} as key(s)", %{conn: conn} do
        user = Haytni.RecoverablePlugin.build_config(reset_password_keys: unquote(keys))
        |> Haytni.RecoverablePlugin.reset_password_attributes()
        |> Keyword.merge(email: "parker.peter@daily-bugle.com", first_name: "Peter", last_name: "Parker")
        |> user_fixture()

        new_conn = post(conn, Routes.password_path(conn, :create), recover_params(user))
        assert contains_formatted_text?(html_response(new_conn, 200), HaytniWeb.Recoverable.PasswordController.recovery_token_sent_message())
      end
    end
  end
end
