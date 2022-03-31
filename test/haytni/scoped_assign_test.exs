defmodule Haytni.ScopedAssignTest do
  use ExUnit.Case, async: true

  test "Haytni.scoped_assign/1" do
    assert :current_admin == Haytni.scoped_assign(HaytniTestWeb.HaytniAdmin)
    assert :current_user == Haytni.scoped_assign(HaytniTestWeb.Haytni)
    assert :current_cr == Haytni.scoped_assign(HaytniTestWeb.HaytniCustomRoutes)
    assert :current_empty == Haytni.scoped_assign(HaytniTestWeb.HaytniEmpty)
  end
end
