defmodule Haytni.Registerable.ValidateCreateRegistrationTest do
  use Haytni.DataCase, async: true

  @fields ~W[email password]a
  @valid_params [
    email: "sarah.croche@dummy.com",
    password: "0123456789",
  ]

  defp to_changeset(params, config) do
    %HaytniTest.User{}
    |> Ecto.Changeset.cast(params, @fields)
    |> Haytni.RegisterablePlugin.validate_create_registration(HaytniTestWeb.Haytni, config)
  end

  defp registration_params(attrs \\ %{}) do
    @valid_params
    |> Params.create(attrs)
    |> Params.confirm(@fields)
  end

  describe "Haytni.RegisterablePlugin.validate_create_registration/3" do
    setup do
      [
        config: Haytni.RegisterablePlugin.build_config(),
      ]
    end

    test "ensures valid values result in a valid changeset without any error", %{config: config} do
      changeset =
        registration_params()
        |> to_changeset(config)

      assert changeset.valid?
      assert %{} == errors_on(changeset)
    end

    for field <- @fields do
      confirmation_field = :"#{field}_confirmation"
      #field_as_string = to_string(field)
      confirmation_field_as_string = to_string(confirmation_field)

      test "ensures #{field} presence", %{config: config} do
        changeset =
          [{unquote(field), ""}]
          |> registration_params()
          |> to_changeset(config)

        refute changeset.valid?
        assert %{unquote(field) => [empty_message()]} == errors_on(changeset)
      end

      test "ensures #{field} confirmation", %{config: config} do
        changeset =
          registration_params()
          |> Map.update!(unquote(confirmation_field_as_string), &String.reverse/1)
          |> to_changeset(config)

        refute changeset.valid?
        assert %{unquote(confirmation_field) => [confirmation_mismatch_message()]} == errors_on(changeset)
      end

      test "ensures keys are normalized to lower case according to *config* with #{field} as case_insensitive_keys", %{config: config} do
        config = %{config | case_insensitive_keys: [unquote(field)]}
        user =
          [{unquote(field), &String.upcase/1}]
          |> registration_params()
          |> to_changeset(config)
          |> Ecto.Changeset.apply_changes()

        assert @valid_params[unquote(field)] == Map.get(user, unquote(field))
      end

      test "ensures keys are trimmed according to *config* with #{field} as strip_whitespace_keys", %{config: config} do
        spaces = " \t\r\n"
        config = %{config | strip_whitespace_keys: [unquote(field)]}
        user =
          [{unquote(field), &(spaces <> &1 <> spaces)}]
          |> registration_params()
          |> to_changeset(config)
          |> Ecto.Changeset.apply_changes()

        assert @valid_params[unquote(field)] == Map.get(user, unquote(field))
      end
    end

    test "ensures email uniqueness", %{config: config} do
      input_changeset =
        registration_params()
        |> to_changeset(config)
        |> Ecto.Changeset.change(encrypted_password: "")

      {:ok, _user} = HaytniTest.Repo.insert(input_changeset)
      # NOTE: unique_constraint will only pop up after a Repo.insert
      {:error, output_changeset} = HaytniTest.Repo.insert(input_changeset)

      refute output_changeset.valid?
      assert %{email: [already_took_message()]} == errors_on(output_changeset)
    end

    test "ensures email format", %{config: config} do
      for email <- ~W[dummy.com] do
        changeset =
          [email: email]
          |> registration_params()
          |> to_changeset(config)

        refute changeset.valid?
        assert %{email: [invalid_format_message()]} == errors_on(changeset)
      end
    end
  end
end
