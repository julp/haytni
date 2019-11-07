defmodule Haytni.Recoverable.ResendConfirmationInstructionsTest do
  use Haytni.DataCase, async: true
  use Bamboo.Test#, shared: true

  alias HaytniTest.User

  @spec create_confirmation(email :: String.t) :: Haytni.Confirmation.t
  defp create_confirmation(email) do
    {:ok, confirmation} = Haytni.Confirmation.create_confirmation(%{email: email})
    confirmation
  end

  @spec confirm_user!(user :: Haytni.user, confirmed_at :: integer) :: Haytni.user
  def confirm_user!(user = %User{id: id}, confirmed_at \\ 300) do
    %User{id: ^id, confirmation_token: nil} = user
    |> Ecto.Changeset.change(confirmed_at: seconds_ago(confirmed_at), confirmation_token: nil)
    |> Haytni.repo().update!()
  end

  describe "Haytni.ConfirmablePlugin.resend_confirmation_instructions/1" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "ensures no email is sent if no one (email) match" do
      result = "no match"
      |> create_confirmation()
      |> Haytni.ConfirmablePlugin.resend_confirmation_instructions()

      assert {:error, :no_match} = result
      #assert_no_emails_delivered() # TODO: assert fails because user_fixture previously sent one
    end

    test "ensures no email is sent if account is already confirmed", %{user: user} do
      confirmed_user = confirm_user!(user)

      result = confirmed_user.email
      |> create_confirmation()
      |> Haytni.ConfirmablePlugin.resend_confirmation_instructions()

      assert {:error, :already_confirmed} = result
      #assert_no_emails_delivered() # TODO: assert fails because user_fixture previously sent one
    end

    test "ensures a new confirmation is sent by email with the same token if last one is not expired", %{user: user} do
      result = user.email
      |> create_confirmation()
      |> Haytni.ConfirmablePlugin.resend_confirmation_instructions()

      assert {:ok, ^user} = result
      assert_delivered_email Haytni.ConfirmableEmail.confirmation_email(user)
    end

    test "ensures a new confirmation is sent by email with the a new token if last one is expired", %{user: user} do
      new_confirmation_sent_at = Haytni.ConfirmablePlugin.confirm_within()
      |> Haytni.duration()
      |> Kernel.+(1)
      |> seconds_ago()

      expired_user = user
      |> Ecto.Changeset.change(confirmation_sent_at: new_confirmation_sent_at)
      |> Haytni.repo().update!()

      {:ok, updated_user} = user.email
      |> create_confirmation()
      |> Haytni.ConfirmablePlugin.resend_confirmation_instructions()

      assert updated_user.id == user.id
      refute updated_user.confirmation_token == expired_user.confirmation_token
      refute updated_user.confirmation_sent_at == expired_user.confirmation_sent_at
      assert_delivered_email Haytni.ConfirmableEmail.confirmation_email(updated_user)
    end
  end
end
