defmodule Haytni.Registerable.UpdateEmailTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RegisterablePlugin,
  ]

  defp email_attrs(email) do
    [
      email: email,
    ]
    |> Params.create()
  end

  @new_email "my@new.address"
  @current_password "0123456789"
  describe "Haytni.RegisterablePlugin.update_email/5" do
    setup do
      [
        user: user_fixture(password: @current_password),
        config: @plugin.build_config(),
      ]
    end

    test "ensures (new) email presence", %{config: config, user: user} do
      {:error, changeset = %Ecto.Changeset{}} = @plugin.update_email(@stack, config, user, @current_password, email_attrs(""))

      refute changeset.valid?
      assert %{email: [empty_message()]} == errors_on(changeset)
    end

    test "ensures email uniqueness is preserved", %{config: config, user: user} do
      other_user = user_fixture()
      {:error, changeset = %Ecto.Changeset{}} = @plugin.update_email(@stack, config, user, @current_password, email_attrs(other_user.email))

      refute changeset.valid?
      assert %{email: [already_took_message()]} == errors_on(changeset)
    end

    test "ensures (new) email changed", %{config: config, user: user} do
      {:error, changeset = %Ecto.Changeset{}} = @plugin.update_email(@stack, config, user, @current_password, email_attrs(user.email))

      refute changeset.valid?
      assert %{email: [@plugin.has_not_changed_message()]} == errors_on(changeset)
    end

    # stolen from validate_create_registration test
    test "ensures (new) email validity (format)", %{config: config, user: user} do
      for email <- ~W[dummy.com] do
        {:error, changeset = %Ecto.Changeset{}} = @plugin.update_email(@stack, config, user, @current_password, email_attrs(email))

        refute changeset.valid?
        assert %{email: [invalid_format_message()]} == errors_on(changeset)
      end
    end

    test "ensures current password is requested on email change", %{config: config, user: user}  do
      {:error, changeset = %Ecto.Changeset{}} = @plugin.update_email(@stack, config, user, "", email_attrs(@new_email))

      refute changeset.valid?
      assert %{current_password: [@plugin.invalid_current_password_message()]} == errors_on(changeset)
    end

    test "ensures error without current password", %{config: config, user: user}  do
      {:error, changeset = %Ecto.Changeset{}} = @plugin.update_email(@stack, config, user, "not the current password", email_attrs(@new_email))

      refute changeset.valid?
      assert %{current_password: [@plugin.invalid_current_password_message()]} == errors_on(changeset)
    end

    test "ensures email changes with current password", %{config: config, user: user}  do
      {:ok, _updated_user = %HaytniTest.User{}} = @plugin.update_email(@stack, config, user, @current_password, email_attrs(@new_email))

      # NOTE: reconfirmable doesn't update the email, it creates a token with context = "reconfirmable:<old email address>" and sent_to = <new email address> instead
      [reconfirmable_token] =
        user
        |> Haytni.Token.tokens_from_user_query(:all)
        |> @repo.all()

      assert reconfirmable_token.sent_to == "my@new.address"
      assert reconfirmable_token.context == Haytni.ConfirmablePlugin.token_context(user.email)
    end
  end
end
