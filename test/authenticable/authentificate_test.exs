defmodule Haytni.Authenticable.AuthentificateTest do
  use HaytniWeb.ConnCase, async: true

  describe "Haytni.AuthenticablePlugin.authentificate/2" do
    @pass "123456"

    setup %{conn: conn} do
      #plugins = Haytni.plugins()
      #Application.put_env(:haytni, :plugins, [Haytni.AuthenticablePlugin])
      #on_exit fn ->
        #Application.put_env(:haytni, :plugins, plugins)
      #end

      {:ok, conn: conn, user: user_fixture(password: @pass)}
    end

    test "returns user with correct password", %{conn: conn, user: user} do
      session = create_session(user.email, @pass)

      # TODO: confirmable invalids authentification
      assert {:ok, user_found} = Haytni.AuthenticablePlugin.authentificate(conn, session)
      assert user_found.id == user.id
    end

    test "returns unauthorized error with invalid password", %{conn: conn, user: user} do
      session = create_session(user.email, "badpass")

      assert {:error, _reason} = Haytni.AuthenticablePlugin.authentificate(conn, session)
    end

    test "returns not found error with no matching user for email", %{conn: conn} do
      session = create_session("nomatch", @pass)

      assert {:error, _reason} = Haytni.AuthenticablePlugin.authentificate(conn, session)
    end
  end
end
