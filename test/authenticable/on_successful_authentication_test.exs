defmodule Haytni.Authenticable.OnSuccessfulAuthenticationTest do
  use HaytniWeb.ConnCase, async: true

  setup %{conn: conn} do
    [
      module: HaytniTestWeb.Haytni,
      conn: Phoenix.ConnTest.init_test_session(conn, %{}),
    ]
  end

  defp check_session_and_multi(user, conn, module, scoped_session_key) do
    config = Haytni.AuthenticablePlugin.build_config()
    {conn, multi, []} = Haytni.AuthenticablePlugin.on_successful_authentication(conn, user, Ecto.Multi.new(), Keyword.new(), module, config)
    session_token = Plug.Conn.get_session(conn, scoped_session_key)

    assert [{:authenticable_token, {:insert, changeset = %Ecto.Changeset{}, []}}] = Ecto.Multi.to_list(multi)
    assert is_binary(session_token)
    assert session_token == Haytni.Token.url_encode(changeset.data)
  end

  describe "Haytni.AuthenticablePlugin.on_successful_authentication/6 (callback)" do
    test ":admin_token key is put in session for HaytniTestWeb.HaytniAdmin", %{conn: conn} do
      admin_fixture()
      |> check_session_and_multi(conn, HaytniTestWeb.HaytniAdmin, :admin_token)
    end

    test ":user_token key is put in session for HaytniTestWeb.Haytni", %{conn: conn} do
      user_fixture()
      |> check_session_and_multi(conn, HaytniTestWeb.Haytni, :user_token)
    end
  end
end
