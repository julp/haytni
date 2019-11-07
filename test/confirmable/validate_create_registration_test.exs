defmodule Haytni.Confirmable.ValidateCreateRegistrationTest do
  use Haytni.DataCase, async: true

  alias HaytniTest.User

  describe "Haytni.ConfirmablePlugin.validate_create_registration/1" do
    test "ensures a confirmation is generated at registration" do
      {:ok, user} = %User{}
      |> Ecto.Changeset.change()
      |> Haytni.ConfirmablePlugin.validate_create_registration()
      |> Ecto.Changeset.apply_action(:insert)

      assert is_binary(user.confirmation_token)
      assert %DateTime{} = user.confirmation_sent_at
    end
  end
end
