defmodule Haytni.ScopedSessionKeyTest do
  use ExUnit.Case, async: true

  test "Haytni.scoped_session_key/1" do
    assert :admin_id == Haytni.scoped_session_key(HaytniTestWeb.HaytniAdmin)
    assert :user_id == Haytni.scoped_session_key(HaytniTestWeb.Haytni)
    assert :cr_id == Haytni.scoped_session_key(HaytniTestWeb.HaytniCustomRoutes)
    assert :empty_id == Haytni.scoped_session_key(HaytniTestWeb.HaytniEmpty)
  end
end
