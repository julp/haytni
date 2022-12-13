defmodule Haytni.PasswordPolicy.ValidatePasswordTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.PasswordPolicyPlugin,
  ]

  describe "Haytni.PasswordPolicyPlugin.validate_password/3" do
    test "checks password length complies to password_length" do
      password = "12345678"
      length = String.length(password)
      changeset =
        %HaytniTest.User{}
        |> Ecto.Changeset.change(password: password)

      for l <- Range.new(length + 1, length + 5) do
        config = @plugin.build_config(password_length: l..128, password_classes_to_match: 0)
        changeset = @plugin.validate_password(changeset, @stack, config)

        refute changeset.valid?
        assert %{password: ["should be at least #{l} character(s)"]} == errors_on(changeset)
      end
      for l <- Range.new(length - 4, length) do
        config = @plugin.build_config(password_length: l..128, password_classes_to_match: 0)
        changeset = @plugin.validate_password(changeset, @stack, config)

        assert changeset.valid?
        assert %{} == errors_on(changeset)
      end
    end

    test "checks password content complies to password_classes_to_match" do
      chars = ["", "a", "A", "0", "!"]
      for a <- chars, b <- chars, c <- chars, d <- chars, l <- 0..4 do
        config = @plugin.build_config(password_length: 0..128, password_classes_to_match: l)
        password = Enum.join([a, b, c, d])
        changeset =
          %HaytniTest.User{}
          |> Ecto.Changeset.change(password: password)
          |> @plugin.validate_password(@stack, config)

        cond do
          password == "" ->
            assert true
          Enum.count(Enum.uniq(String.codepoints(password))) >= config.password_classes_to_match ->
            assert changeset.valid?
            assert %{} == errors_on(changeset)
          true ->
            refute changeset.valid?
            assert %{password: [@plugin.invalid_password_format_message(config)]} == errors_on(changeset)
        end
      end
    end
  end
end
