defmodule Haytni.Registerable.UpdateEmailTest do
  use Haytni.DataCase, async: true

  defp email_attrs(email) do
    [
      email: email,
    ]
    |> Params.create()
  end

  @new_email "my@new.address"
  @current_password "0123456789"
  #@moduletag plugin: Haytni.RegisterablePlugin
  describe "Haytni.RegisterablePlugin.update_email/5" do
    setup do
      [
        user: user_fixture(password: @current_password),
        module: HaytniTestWeb.Haytni,
        #plugin: Haytni.RegisterablePlugin,
        config: Haytni.RegisterablePlugin.build_config(),
      ]
    end

    test "ensures (new) email presence", %{module: module, config: config, user: user} do
      {:error, changeset = %Ecto.Changeset{}} = Haytni.RegisterablePlugin.update_email(module, config, user, @current_password, email_attrs(""))

      refute changeset.valid?
      assert %{email: [empty_message()]} == errors_on(changeset)
    end

    test "ensures email uniqueness is preserved", %{module: module, config: config, user: user} do
      other_user = user_fixture()
      {:error, changeset = %Ecto.Changeset{}} = Haytni.RegisterablePlugin.update_email(module, config, user, @current_password, email_attrs(other_user.email))

      refute changeset.valid?
      assert %{email: [already_took_message()]} == errors_on(changeset)
    end

    test "ensures (new) email changed", %{module: module, config: config, user: user} do
      {:error, changeset = %Ecto.Changeset{}} = Haytni.RegisterablePlugin.update_email(module, config, user, @current_password, email_attrs(user.email))

      refute changeset.valid?
      assert %{email: [Haytni.RegisterablePlugin.has_not_changed_message()]} == errors_on(changeset)
    end

    # stolen from validate_create_registration test
    test "ensures (new) email validity (format)", %{module: module, config: config, user: user} do
      for email <- ~W[dummy.com] do
        {:error, changeset = %Ecto.Changeset{}} = Haytni.RegisterablePlugin.update_email(module, config, user, @current_password, email_attrs(email))

        refute changeset.valid?
        assert %{email: [invalid_format_message()]} == errors_on(changeset)
      end
    end

    test "ensures current password is requested on email change", %{module: module, config: config, user: user}  do
      {:error, changeset = %Ecto.Changeset{}} = Haytni.RegisterablePlugin.update_email(module, config, user, "", email_attrs(@new_email))

      refute changeset.valid?
      assert %{current_password: [Haytni.RegisterablePlugin.invalid_current_password_message()]} == errors_on(changeset)
    end

    test "ensures error without current password", %{module: module, config: config, user: user}  do
      {:error, changeset = %Ecto.Changeset{}} = Haytni.RegisterablePlugin.update_email(module, config, user, "not the current password", email_attrs(@new_email))

      refute changeset.valid?
      assert %{current_password: [Haytni.RegisterablePlugin.invalid_current_password_message()]} == errors_on(changeset)
    end

    test "ensures email changes with current password", %{module: module, config: config, user: user}  do
      {:ok, _updated_user = %HaytniTest.User{}} = Haytni.RegisterablePlugin.update_email(module, config, user, @current_password, email_attrs(@new_email))

      # NOTE: reconfirmable doesn't update the email, it creates a token with context = "reconfirmable:<old email address>" and sent_to = <new email address> instead
      [reconfirmable_token] =
        user
        |> Haytni.Token.tokens_from_user_query(:all)
        |> HaytniTest.Repo.all()

      assert reconfirmable_token.sent_to == "my@new.address"
      assert reconfirmable_token.context == Haytni.ConfirmablePlugin.token_context(user.email)
    end
  end
end
