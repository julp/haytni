defmodule Haytni.Recoverable.RecoverTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RecoverablePlugin,
  ]

  alias HaytniTest.User

  defp new_password_change(reset_token, new_password) do
    %{
      "password" => new_password,
      "password_confirmation" => new_password,
      "reset_password_token" => reset_token,
    }
  end

  describe "Haytni.RecoverablePlugin.recover/3" do
    setup do
      _some_random_guy = user_fixture()

      [
        user: user_fixture(),
        config: @plugin.build_config(),
      ]
    end

    test "ensures error when reset params are empty", %{config: config} do
      assert {:error, changeset} = @plugin.recover(@stack, config, new_password_change("", ""))
      refute is_nil(changeset.action)
      assert %{reset_password_token: [empty_message()], password: [empty_message()]} == Haytni.DataCase.errors_on(changeset)
    end

    test "ensures error when reset token doesn't exist", %{config: config} do
      assert {:error, changeset} = @plugin.recover(@stack, config, new_password_change("not a match", "unused new password"))
      refute is_nil(changeset.action)
      assert %{reset_password_token: [@plugin.invalid_token_message()]} == Haytni.DataCase.errors_on(changeset)
    end

    test "ensures error when reset token has expired (and password remains the same)", %{config: config, user: user = %User{id: id, encrypted_password: encrypted_password}} do
      reset_password_token =
        user
        |> token_fixture(@plugin, inserted_at: config.reset_password_within + 1)
        |> Haytni.Token.url_encode()

      assert {:error, changeset} = @plugin.recover(@stack, config, new_password_change(reset_password_token, "unused new password"))
      refute is_nil(changeset.action)
      # ensure password hasn't changed
      assert %User{id: ^id, encrypted_password: ^encrypted_password} = HaytniTest.Users.get_user!(id)
    end

    test "ensures password was reseted in normal condition", %{config: config, user: user} do
      new_password = "this is my new password"
      reset_password_token =
        user
        |> token_fixture(@plugin)
        |> Haytni.Token.url_encode()

      assert {:ok, updated_user} = @plugin.recover(@stack, config, new_password_change(reset_password_token, new_password))

      assert updated_user.id == user.id
      assert String.starts_with?(updated_user.encrypted_password, "$2b$")
      assert Haytni.AuthenticablePlugin.valid_password?(updated_user, new_password, @stack.fetch_config(Haytni.AuthenticablePlugin))
    end

    test "ensures new password respects minimal length", %{config: config, user: user} do
      reset_password_token =
        user
        |> token_fixture(@plugin)
        |> Haytni.Token.url_encode()

      assert {:error, changeset} = @plugin.recover(@stack, config, new_password_change(reset_password_token, "1"))
      assert %{password: [reason]} = errors_on(changeset)
      assert reason =~ ~R"should be at least \d+ character\(s\)"
    end
  end
end
