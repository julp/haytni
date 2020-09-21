defmodule Haytni.Confirmable.ValidateCreateRegistrationTest do
  use Haytni.DataCase, async: true

  alias HaytniTest.User

  describe "Haytni.ConfirmablePlugin.validate_create_registration/2" do
    test "ensures a confirmation is generated at registration" do
      config = Haytni.ConfirmablePlugin.build_config()

      {:ok, user} =
        %User{}
        |> Ecto.Changeset.change()
        |> Haytni.ConfirmablePlugin.validate_create_registration(config)
        |> Ecto.Changeset.apply_action(:insert)

      assert is_binary(user.confirmation_token)
      assert %DateTime{} = user.confirmation_sent_at
    end
  end
end
