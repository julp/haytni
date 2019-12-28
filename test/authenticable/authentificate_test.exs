defmodule Haytni.Authenticable.AuthentificateTest do
  use HaytniWeb.ConnCase, async: true

  @spec create_session(email :: String.t, password :: String.t) :: %{String.t => String.t}
  defp create_session(email, password) do
    %{"email" => email, "password" => password}
  end

  describe "Haytni.AuthenticablePlugin.authenticate/4" do
    @pass "123456"

    setup do
      config = HaytniTestWeb.Haytni.fetch_config(Haytni.AuthenticablePlugin)
      user = #HaytniTestWeb.Haytni.fetch_config(Haytni.ConfirmablePlugin)
      Haytni.ConfirmablePlugin.reset_confirmation_attributes()
      |> Keyword.put(:password, @pass)
      |> user_fixture()

      {:ok, config: config, user: user}
    end

    test "returns user with correct password", %{conn: conn, config: config, user: user} do
      session = create_session(user.email, @pass)

      assert {:ok, new_conn} = Haytni.AuthenticablePlugin.authenticate(conn, HaytniTestWeb.Haytni, config, session)
      assert new_conn.assigns.current_user.id == user.id
    end

    test "returns error with empty credentials", %{conn: conn, config: config} do
      session = create_session("", "")

      assert {:error, changeset} = Haytni.AuthenticablePlugin.authenticate(conn, HaytniTestWeb.Haytni, config, session)
      refute is_nil(changeset.action)
      assert %{email: [empty_message()], password: [empty_message()]} == Haytni.DataCase.errors_on(changeset)
    end

    test "returns unauthorized error with invalid password", %{conn: conn, config: config, user: user} do
      session = create_session(user.email, "badpass")

      assert {:error, changeset} = Haytni.AuthenticablePlugin.authenticate(conn, HaytniTestWeb.Haytni, config, session)
      refute is_nil(changeset.action)
      assert %{base: [Haytni.AuthenticablePlugin.invalid_credentials_message()]} == Haytni.DataCase.errors_on(changeset)
    end

    test "returns not found error with no matching user for email", %{conn: conn, config: config} do
      session = create_session("nomatch", @pass)

      assert {:error, changeset} = Haytni.AuthenticablePlugin.authenticate(conn, HaytniTestWeb.Haytni, config, session)
      refute is_nil(changeset.action)
      assert %{base: [Haytni.AuthenticablePlugin.invalid_credentials_message()]} == Haytni.DataCase.errors_on(changeset)
    end
  end
end
