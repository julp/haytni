defmodule Haytni.Tokenable.TokenControllerTest do
  use HaytniWeb.ConnCase, async: true

  describe "HaytniWeb.Tokenable.TokenController#create" do
    test "gets forbidden if not logged in", %{conn: conn} do
      conn
      |> post(Routes.haytni_user_token_path(conn, :create))
      |> json_response(403)
      |> (& assert &1 == nil).()
    end

    test "acquires a token if logged in", %{conn: conn} do
      user = user_fixture()

      conn
      |> assign(:current_user, user)
      |> post(Routes.haytni_user_token_path(conn, :create))
      |> json_response(200)
      |> (& assert is_binary(&1)).()
    end
  end
end
