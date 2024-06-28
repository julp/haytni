defmodule Haytni.Authenticable.AuthenticateTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.AuthenticablePlugin,
  ]

  @spec create_session(email :: String.t, password :: String.t) :: Haytni.params
  defp create_session(email, password) do
    %{
      "email" => email,
      "password" => password,
    }
  end

  @spec assert_invalid_credentials(conn :: Plug.Conn.t, config :: HaytniTestWeb.Haytni.Config.t, module :: module, session :: Haytni.params) :: boolean | no_return
  defp assert_invalid_credentials(conn, config, module, session) do
    assert {:error, changeset} = @plugin.authenticate(conn, module, config, session)
    refute is_nil(changeset.action)
    assert %{base: [@plugin.invalid_credentials_message()]} == Haytni.DataCase.errors_on(changeset)
  end

  describe "Haytni.AuthenticablePlugin.authenticate/4" do
    @pass "123456"

    setup %{conn: conn} do
      admin = admin_fixture(password: @pass)
      config = @stack.fetch_config(@plugin)
      user =
        Haytni.ConfirmablePlugin.confirmed_attributes()
        |> Keyword.put(:password, @pass)
        |> user_fixture()

      [
        user: user,
        admin: admin,
        config: config,
        conn: Plug.Test.init_test_session(conn, %{}),
      ]
    end

    test "returns user with correct password", %{conn: conn, config: config, user: user} do
      session = create_session(user.email, @pass)

      assert {:ok, conn} = @plugin.authenticate(conn, @stack, config, session)
      assert user.id == conn.assigns.current_user.id
    end

    test "user's password is updated on successful authentication", %{conn: conn, config: config, user: user} do
      session = create_session(user.email, @pass)

      assert String.starts_with?(user.encrypted_password, "$2b$04$")
      config = %{config | hashing_options: %{cost: 5}}
      assert {:ok, conn} = @plugin.authenticate(conn, @stack, config, session)
      assert user.id == conn.assigns.current_user.id

      updated_user = @stack.repo().get(user.__struct__, user.id)
      assert String.starts_with?(updated_user.encrypted_password, "$2b$05$")
      assert @plugin.valid_password?(updated_user, @pass, config)
    end

    test "check user/admin scopes do not mix", %{conn: conn, config: config, user: user, admin: admin} do
      assert_invalid_credentials(conn, config, HaytniTestWeb.HaytniAdmin, create_session(user.email, @pass))
      assert_invalid_credentials(conn, config, @stack, create_session(admin.email, @pass))
    end

    test "returns admin with correct password", %{conn: conn, config: config, admin: admin} do
      session = create_session(admin.email, @pass)

      assert {:ok, conn} = @plugin.authenticate(conn, HaytniTestWeb.HaytniAdmin, config, session)
      assert admin.id == conn.assigns.current_admin.id
    end

    test "returns error with empty credentials", %{conn: conn, config: config} do
      session = create_session("", "")

      assert {:error, changeset} = @plugin.authenticate(conn, @stack, config, session)
      refute is_nil(changeset.action)
      assert %{email: [empty_message()], password: [empty_message()]} == Haytni.DataCase.errors_on(changeset)
    end

    test "returns unauthorized error with invalid password", %{conn: conn, config: config, user: user} do
      assert_invalid_credentials(conn, config, @stack, create_session(user.email, "badpass"))
    end

    test "returns not found error with no matching user for email", %{conn: conn, config: config} do
      assert_invalid_credentials(conn, config, @stack, create_session("nomatch", @pass))
    end
  end
end
