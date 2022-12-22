defmodule Haytni.Confirmable.ReconfirmTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.ConfirmablePlugin,
  ]

  describe "Haytni.ConfirmablePlugin.reconfirm/4" do
    setup do
      [
        config: @plugin.build_config(),
        user: user_fixture(confirmed_at: Haytni.Helpers.now()),
      ]
    end

    test "gets error on invalid tokens", %{config: config, user: user} do
      for reconfirmation_token <- ["", "\x00"] do
        assert {:error, @plugin.invalid_token_message()} == @plugin.reconfirm(@stack, config, user, reconfirmation_token)
      end
    end

    test "gets error on invalid (missmatch) token", %{config: config, user: user} do
      assert {:error, @plugin.invalid_token_message()} == @plugin.reconfirm(@stack, config, user, Base.url_encode64("not a match"))
    end

    test "gets error on expired token", %{config: config, user: user} do
      reconfirmation_token =
        user
        |> token_fixture(@plugin, sent_to: "my@new.address", token: "z0g2NoDkw9", context: @plugin.token_context(user.email), inserted_at: config.reconfirm_within + 1)
        |> Haytni.Token.url_encode()

      assert {:error, @plugin.invalid_token_message()} == @plugin.reconfirm(@stack, config, user, reconfirmation_token)
    end

    test "ensures email is successfully changed on reconfirmation", %{config: config, user: user} do
      new_email_address = "my@new.address"
      reconfirmation_token =
        user
        |> token_fixture(@plugin, sent_to: new_email_address, token: "aRGFh5Rdo5", context: @plugin.token_context(user.email), inserted_at: config.reconfirm_within - 1)
        |> Haytni.Token.url_encode()

      assert {:ok, updated_user} = @plugin.reconfirm(@stack, config, user, reconfirmation_token)
      assert updated_user.id == user.id
      assert updated_user.email == new_email_address
      refute is_nil(updated_user.confirmed_at)
    end
  end
end
