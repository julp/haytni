defmodule Haytni.Registerable.RegisterableTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.RegisterablePlugin,
  ]

  @types %{untouched: :string, email: :string}

  setup do
    [
      config: @plugin.build_config(),
    ]
  end

  test "stripping whitespace from selected inputs", %{config: config} do
    data =
      {%{}, @types}
      |> Ecto.Changeset.cast(%{"untouched" => " abc ", "email" => "\t123\r\n"}, Map.keys(@types))
      |> @plugin.strip_whitespace_changes(config)
      |> Ecto.Changeset.apply_changes()

    assert data == %{untouched: " abc ", email: "123"}
  end

  test "downcasing selected inputs", %{config: config} do
    data =
      {%{}, @types}
      |> Ecto.Changeset.cast(%{"untouched" => "FOO", "email" => "BAR"}, Map.keys(@types))
      |> @plugin.case_insensitive_changes(config)
      |> Ecto.Changeset.apply_changes()

    assert data == %{untouched: "FOO", email: "bar"}
  end
end
