defmodule Haytni.Authenticable.AuthentificateTest do
  use HaytniWeb.ConnCase, async: true

  @spec create_session(email :: String.t, password :: String.t) :: %{String.t => String.t}
  defp create_session(email, password) do
    %{"email" => email, "password" => password}
  end

  @spec assert_invalid_credentials(conn :: Plug.Conn.t, config :: HaytniTestWeb.Haytni.Config.t, module :: module, session :: %{String.t => String.t}) :: boolean | no_return
  defp assert_invalid_credentials(conn, config, module, session) do
    assert {:error, changeset} = Haytni.AuthenticablePlugin.authenticate(conn, module, config, session)
    refute is_nil(changeset.action)
    assert %{base: [Haytni.AuthenticablePlugin.invalid_credentials_message()]} == Haytni.DataCase.errors_on(changeset)
  end

  describe "Haytni.AuthenticablePlugin.authenticate/4" do
    @pass "123456"

    setup do
      admin = admin_fixture(password: @pass)
      config = HaytniTestWeb.Haytni.fetch_config(Haytni.AuthenticablePlugin)
      user = #HaytniTestWeb.Haytni.fetch_config(Haytni.ConfirmablePlugin)
      Haytni.ConfirmablePlugin.reset_confirmation_attributes()
      |> Keyword.put(:password, @pass)
      |> user_fixture()

      {:ok, config: config, user: user, admin: admin}
    end

    test "returns user with correct password", %{conn: conn, config: config, user: user} do
      session = create_session(user.email, @pass)

      assert {:ok, new_conn} = Haytni.AuthenticablePlugin.authenticate(conn, HaytniTestWeb.Haytni, config, session)
      assert new_conn.assigns.current_user.id == user.id
    end

    test "check user/admin scopes do not mix", %{conn: conn, config: config, user: user, admin: admin} do
      assert_invalid_credentials(conn, config, HaytniTestWeb.HaytniAdmin, create_session(user.email, @pass))
      assert_invalid_credentials(conn, config, HaytniTestWeb.Haytni, create_session(admin.email, @pass))
    end

    test "returns admin with correct password", %{conn: conn, config: config, admin: admin} do
      session = create_session(admin.email, @pass)

      assert {:ok, new_conn} = Haytni.AuthenticablePlugin.authenticate(conn, HaytniTestWeb.HaytniAdmin, config, session)
      assert new_conn.assigns.current_admin.id == admin.id
    end

    test "returns error with empty credentials", %{conn: conn, config: config} do
      session = create_session("", "")

      assert {:error, changeset} = Haytni.AuthenticablePlugin.authenticate(conn, HaytniTestWeb.Haytni, config, session)
      refute is_nil(changeset.action)
      assert %{email: [empty_message()], password: [empty_message()]} == Haytni.DataCase.errors_on(changeset)
    end

    test "returns unauthorized error with invalid password", %{conn: conn, config: config, user: user} do
      assert_invalid_credentials(conn, config, HaytniTestWeb.Haytni, create_session(user.email, "badpass"))
    end

    test "returns not found error with no matching user for email", %{conn: conn, config: config} do
      assert_invalid_credentials(conn, config, HaytniTestWeb.Haytni, create_session("nomatch", @pass))
    end
  end
end
