defmodule Haytni.HelpersTest do
  use ExUnit.Case, async: true

  test "duration/1" do
    assert Haytni.Helpers.duration(3) == 3
    assert Haytni.Helpers.duration({4, :second}) == 4
    assert Haytni.Helpers.duration({5, :minute}) == 300
    assert Haytni.Helpers.duration({6, :hour}) == 21_600
    assert Haytni.Helpers.duration({7, :day}) == 604_800
    assert Haytni.Helpers.duration({8, :week}) == 4_838_400
    assert Haytni.Helpers.duration({9, :month}) == 23_328_000
    assert Haytni.Helpers.duration({10, :year}) == 315_360_000

    # something else
    assert_raise FunctionClauseError, fn ->
      Haytni.Helpers.duration({11, :decade})
    end
  end
end
