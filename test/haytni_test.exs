defmodule HaytniTest do
  use ExUnit.Case, async: false
  doctest Haytni

  setup do
    #Application.put_env(:haytni, :plugins, [])
    on_exit fn ->
      #
    end
  end

  test "true" do
    assert true
  end
end
