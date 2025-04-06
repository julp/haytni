defmodule Haytni.Recoverable.PasswordHTMLTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.RecoverablePlugin,
  ]

  @email "tony.stark@stark-industries.com"
  @firstname "Tony"
  @lastname "Stark"
  setup %{conn: conn} do
    user_fixture(email: @email, firstname: @firstname, lastname: @lastname)

    [
      conn: get(conn, Routes.haytni_user_password_path(conn, :new)),
    ]
  end

  defp do_test(conn, config, params) do
    changeset = if map_size(params) == 0 do
      @plugin.recovering_changeset(config)
    else
      {:error, changeset} = @plugin.send_reset_password_instructions(@stack, config, params)
      changeset
    end
    content = Phoenix.Template.render_to_string(@stack.User.PasswordHTML, "new", "html", conn: conn, changeset: changeset, config: config, module: @stack)

    for key <- config.reset_password_keys do
      assert content =~ "name=\"password[#{key}]\""
    end

    if map_size(params) != 0 do
      assert contains_text?(content, Haytni.Helpers.no_match_message())
    end
  end

  @configs [
    {@plugin.build_config(), %{"email" => "iron-man@stark-industries.com"}},
    {@plugin.build_config(reset_password_keys: ~W[firstname lastname]a), %{"firstname" => "Iron", "lastname" => "Man"}},
  ]

  for {config, _params} <- @configs do
    test "renders \"empty\" new.html with #{inspect(config.reset_password_keys)} as key(s)", %{conn: conn} do
      do_test(conn, unquote(Macro.escape(config)), %{})
    end

    # NOTE: the purpose of this test is to check that changeset errors are displayed
    # previously I've forgotten to apply an action so they weren't shown in several places
    # we kinda simulate a create action (which renders also new.html)
    #test "renders new.html with #{inspect(config.reset_password_keys)} as key(s) and bad params", %{conn: conn} do
      #do_test(conn, unquote(Macro.escape(config)), unquote(Macro.escape(params)))
    #end
  end

  test "renders edit.html", %{conn: conn} do
    changeset = Haytni.Recoverable.PasswordChange.change_password(@stack, %{})
    content = Phoenix.Template.render_to_string(@stack.User.PasswordHTML, "edit", "html", conn: conn, changeset: changeset, module: @stack)
    assert content =~ "name=\"password[password]\""
    assert content =~ "name=\"password[password_confirmation]\""
  end

  # NOTE: to uncomment if/when validation are added to values on unlock_keys
  #test "renders edit.html with bad token", %{conn: conn} do
    #module = @stack
    #config = @plugin.build_config()

    #{:error, changeset} = @plugin.recover(module, config, %{"reset_password_token" => "not a match", "password" => "H1b0lnc9c!ZPGTr9Itje", "password_confirmation" => "H1b0lnc9c!ZPGTr9Itje"})
    #content = Phoenix.Template.render_to_string(@stack.User.PasswordHTML, "edit", "html", conn: conn, changeset: changeset, module: module)
    #assert content =~ "name=\"password[password]\""
    #assert content =~ "name=\"password[password_confirmation]\""
    #assert contains_text?(content, @plugin.invalid_token_message())
  #end
end
