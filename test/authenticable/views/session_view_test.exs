defmodule Haytni.Authenticable.SessionViewTest do
  use HaytniWeb.ConnCase, async: true
  import Phoenix.View

  @email "tony.stark@stark-industries.com"
  @firstname "Tony"
  @lastname "Stark"
  setup %{conn: conn} do
    user_fixture(email: @email, firstname: @firstname, lastname: @lastname, password: "not a secret")

    {:ok, conn: get(conn, Routes.haytni_user_session_path(conn, :new))}
  end

  defp do_test(conn, config, params) do
    changeset = if map_size(params) == 0 do
      Haytni.AuthenticablePlugin.session_changeset(config)
    else
      {:error, changeset} = Haytni.AuthenticablePlugin.authenticate(conn, HaytniTestWeb.Haytni, config, params)
      changeset
    end
    content = render_to_string(HaytniTestWeb.Haytni.SessionView, "new.html", conn: conn, changeset: changeset, config: config, module: HaytniTestWeb.Haytni)
    assert String.contains?(content, "name=\"session[password]\"")

    for key <- config.authentication_keys do
      assert String.contains?(content, "name=\"session[#{key}]\"")
    end

    if map_size(params) != 0 do
      assert contains_text?(content, Haytni.AuthenticablePlugin.invalid_credentials_message())
    end
  end

  @configs [
    {Haytni.AuthenticablePlugin.build_config(), %{"email" => @email, "password" => "not a match"}},
    {Haytni.AuthenticablePlugin.build_config(authentication_keys: ~W[firstname lastname]a), %{"firstname" => @firstname, "lastname" => @lastname, "password" => "not a match"}},
  ]

  for {config, params} <- @configs do
    keys = Enum.join(config.authentication_keys, ", ")

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
