defmodule Haytni.ViewsAndTemplatesTest do
  use ExUnit.Case, async: true

  test "quick testing of Haytni views and templates" do
    Haytni.QuickViewsAndTemplatesTest.check_views_and_templates(HaytniTestWeb.Haytni)
  end
end
