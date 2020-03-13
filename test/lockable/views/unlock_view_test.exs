defmodule Haytni.Lockable.UnlockViewTest do
  use HaytniWeb.ConnCase, async: true
  import Phoenix.View

  @email "tony.stark@stark-industries.com"
  @firstname "Tony"
  @lastname "Stark"
  setup %{conn: conn} do
    user_fixture(email: @email, firstname: @firstname, lastname: @lastname, password: "not a secret")

    {:ok, conn: get(conn, Routes.unlock_path(conn, :new))}
  end

  defp do_test(conn, config, params) do
    changeset = if map_size(params) == 0 do
      Haytni.LockablePlugin.unlock_request_changeset(config)
    else
      {:error, changeset} = Haytni.LockablePlugin.resend_unlock_instructions(HaytniTestWeb.Haytni, config, params)
      changeset
    end
    content = render_to_string(HaytniTestWeb.Haytni.UnlockView, "new.html", conn: conn, changeset: changeset, config: config, module: HaytniTestWeb.Haytni)

    for key <- config.unlock_keys do
      assert String.contains?(content, "name=\"unlock[#{key}]\"")
    end

    if map_size(params) != 0 do
      assert contains_text?(content, Haytni.Helpers.no_match_message())
    end
  end

  @configs [
    {Haytni.LockablePlugin.build_config(), %{"email" => "iron-man@stark-industries.com"}},
    {Haytni.LockablePlugin.build_config(unlock_keys: ~W[firstname lastname]a), %{"firstname" => "Iron", "lastname" => "Man"}},
  ]

  for {config, params} <- @configs do
    keys = Enum.join(config.unlock_keys, ", ")

    test "renders \"empty\" new.html with #{keys} as key(s)", %{conn: conn} do
      do_test(conn, unquote(Macro.escape(config)), %{})
    end

    # NOTE: the purpose of this test is to check that changeset errors are displayed
    # previously I've forgotten to apply an action so they weren't shown in several places
    # we kinda simulate a create action (which renders also new.html)
    test "renders new.html with #{keys} as key(s) and bad params", %{conn: conn} do
      do_test(conn, unquote(Macro.escape(config)), unquote(Macro.escape(params)))
    end
  end
end