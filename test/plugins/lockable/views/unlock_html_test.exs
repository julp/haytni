defmodule Haytni.Lockable.UnlockHTMLTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.LockablePlugin,
  ]

  @email "tony.stark@stark-industries.com"
  @firstname "Tony"
  @lastname "Stark"
  setup %{conn: conn} do
    user_fixture(email: @email, firstname: @firstname, lastname: @lastname, password: "not a secret")

    [
      conn: get(conn, Routes.haytni_user_unlock_path(conn, :new)),
    ]
  end

  defp do_test(conn, view, config, params) do
    changeset =
      if map_size(params) == 0 do
        @plugin.unlock_request_changeset(config)
      else
        {:error, _failed_operation, changeset, _changes_so_far} = @plugin.resend_unlock_instructions(HaytniTestWeb.Haytni, config, params)
        changeset
      end
    content = Phoenix.Template.render_to_string(view, "new", "html", conn: conn, changeset: changeset, config: config, module: HaytniTestWeb.Haytni)

    for key <- config.unlock_keys do
      assert content =~ "name=\"unlock[#{key}]\""
    end

    #if map_size(params) != 0 do
      #assert contains_text?(content, Haytni.Helpers.no_match_message())
    #end
  end

  @scopes [
    {:user, HaytniTestWeb.Haytni.User.UnlockHTML},
    {:admin, HaytniTestWeb.Haytni.UnlockHTML},
  ]

  @configs [
    {@plugin.build_config(), %{"email" => "iron-man@stark-industries.com"}},
    {@plugin.build_config(unlock_keys: ~W[firstname lastname]a), %{"firstname" => "Iron", "lastname" => "Man"}},
  ]

  for {config, _params} <- @configs, {scope, view} <- @scopes do
    test "renders \"empty\" new.html with #{inspect(config.unlock_keys)} as key(s) for scope = #{inspect(scope)}", %{conn: conn} do
      do_test(conn, unquote(view), unquote(Macro.escape(config)), %{})
    end

    # NOTE: the purpose of this test is to check that changeset errors are displayed
    # previously I've forgotten to apply an action so they weren't shown in several places
    # we kinda simulate a create action (which renders also new.html)
    # NOTE: to uncomment if/when validation are added to values on unlock_keys
    #test "renders new.html with #{inspect(config.unlock_keys)} as key(s) and bad params for scope = #{inspect(scope)}", %{conn: conn} do
      #do_test(conn, unquote(view), unquote(Macro.escape(config)), unquote(Macro.escape(params)))
    #end
  end
end
