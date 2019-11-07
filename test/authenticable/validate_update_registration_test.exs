defmodule Haytni.Authenticable.ValidateUpdateRegistrationTest do
  use Haytni.DataCase, async: true

  alias HaytniTest.User

  @password "this is my password"
  describe "Haytni.AuthenticablePlugin.validate_update_registration/1" do
    setup do
      {:ok, user: user_fixture(password: @password)}
    end

    test "doesn't interfere if email nor password are changed" do
      changeset = %User{}
      |> Ecto.Changeset.change(dummy: true)

      assert changeset == Haytni.AuthenticablePlugin.validate_update_registration(changeset)
    end

    # NOTE: current_password field is required by registerable
    # In AuthenticablePlugin we just check if it matches and hash the new one
    test "current password has to match before updating email and/or password", %{user: user} do
      ~W[email password]a
      |> Enum.each(
        fn field ->
          changes = Keyword.new()
          |> Keyword.put(field, "dummy new value")

          changeset = user
          |> Ecto.Changeset.change(Keyword.put(changes, :current_password, "wrong password"))
          |> Haytni.AuthenticablePlugin.validate_update_registration()

          assert %{current_password: ["password mismatch"]} = errors_on(changeset)

          changeset = user
          |> Ecto.Changeset.change(Keyword.put(changes, :current_password, @password))
          |> Haytni.AuthenticablePlugin.validate_update_registration()

          assert changeset.valid?
        end
      )
    end

    @new_password "this is my new password"
    test "password is changed (and hashed)", %{user: user} do
      changeset = user
      |> Ecto.Changeset.change(current_password: @password, password: @new_password)
      |> Haytni.AuthenticablePlugin.validate_update_registration()

      new_hash = Ecto.Changeset.get_change(changeset, :encrypted_password)

      assert changeset.valid?
      assert String.starts_with?(new_hash, "$2b$")
      refute new_hash == user.encrypted_password
      assert Haytni.AuthenticablePlugin.check_password(Ecto.Changeset.apply_changes(changeset), @new_password)
    end
  end
end
