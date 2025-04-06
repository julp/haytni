defmodule Haytni.Confirmable.ConfirmationHTMLTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.ConfirmablePlugin,
  ]

  @email "tony.stark@stark-industries.com"
  @firstname "Tony"
  @lastname "Stark"
  setup %{conn: conn} do
    user_fixture(email: @email, firstname: @firstname, lastname: @lastname)

    [
      conn: get(conn, Routes.haytni_user_confirmation_path(conn, :new)),
    ]
  end

  defp do_test(conn, config, params) do
    changeset = if map_size(params) == 0 do
      @plugin.confirmation_request_changeset(config)
    else
      {:error, changeset} = @plugin.resend_confirmation_instructions(@stack, config, params)
      changeset
    end
    content = Phoenix.Template.render_to_string(@stack.User.ConfirmationHTML, "new", "html", conn: conn, changeset: changeset, config: config, module: @stack)

    for key <- config.confirmation_keys do
      assert String.contains?(content, "name=\"confirmation[#{key}]\"")
    end

    if map_size(params) != 0 do
      assert contains_text?(content, Haytni.Helpers.no_match_message())
    end
  end

  @configs [
    {@plugin.build_config(), %{"email" => "iron-man@stark-industries.com"}},
    {@plugin.build_config(confirmation_keys: ~W[firstname lastname]a), %{"firstname" => "Iron", "lastname" => "Man"}},
  ]

  for {config, _params} <- @configs do
    test "renders \"empty\" new.html with #{inspect(config.confirmation_keys)} as key(s)", %{conn: conn} do
      do_test(conn, unquote(Macro.escape(config)), %{})
    end

    # NOTE: the purpose of this test is to check that changeset errors are displayed
    # previously I've forgotten to apply an action so they weren't shown in several places
    # we kinda simulate a create action (which renders also new.html)
    # NOTE: to uncomment if/when validation are added to values on confirmation_keys
    #test "renders new.html with #{keys} as key(s) and bad params", %{conn: conn} do
      #do_test(conn, unquote(Macro.escape(config)), unquote(Macro.escape(params)))
    #end
  end
end
