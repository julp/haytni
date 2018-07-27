defmodule Haytni.Registerable.RegisterableTest do
  use ExUnit.Case, async: true

  #import Ecto.Changeset

  @types %{untouched: :string, email: :string}

  test "stripping whitespace from selected inputs" do
    data = {%{}, @types}
    |> Ecto.Changeset.cast(%{"untouched" => " abc ", "email" => "\t123\r\n"}, Map.keys(@types))
    |> Haytni.RegisterablePlugin.strip_whitespace_changes()
    |> Ecto.Changeset.apply_changes()

    assert data == %{untouched: " abc ", email: "123"}
  end

  test "downcasing selected inputs" do
    data = {%{}, @types}
    |> Ecto.Changeset.cast(%{"untouched" => "FOO", "email" => "BAR"}, Map.keys(@types))
    |> Haytni.RegisterablePlugin.case_insensitive_changes()
    |> Ecto.Changeset.apply_changes()

    assert data == %{untouched: "FOO", email: "bar"}
  end
end
