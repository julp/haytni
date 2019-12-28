defmodule Haytni.Registerable.RegisterableTest do
  use ExUnit.Case, async: true

  @types %{untouched: :string, email: :string}

  setup do
    {:ok, config: Haytni.RegisterablePlugin.build_config()}
  end

  test "stripping whitespace from selected inputs", %{config: config} do
    data = {%{}, @types}
    |> Ecto.Changeset.cast(%{"untouched" => " abc ", "email" => "\t123\r\n"}, Map.keys(@types))
    |> Haytni.RegisterablePlugin.strip_whitespace_changes(config)
    |> Ecto.Changeset.apply_changes()

    assert data == %{untouched: " abc ", email: "123"}
  end

  test "downcasing selected inputs", %{config: config} do
    data = {%{}, @types}
    |> Ecto.Changeset.cast(%{"untouched" => "FOO", "email" => "BAR"}, Map.keys(@types))
    |> Haytni.RegisterablePlugin.case_insensitive_changes(config)
    |> Ecto.Changeset.apply_changes()

    assert data == %{untouched: "FOO", email: "bar"}
  end
end
