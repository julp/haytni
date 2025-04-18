defmodule Haytni.Rememberable.OnSuccessfulAuthentificationTest do
  use HaytniWeb.ConnCase, [
    async: true,
    plugin: Haytni.RememberablePlugin,
  ]

  if false do
  @doc """
  Creates the parameters to simulate a "permanent" sign in action.

  Example:

      iex> #{__MODULE__}.session_params_with_rememberme(%{"email" => "foo@bar.com", "password" => "azerty"})
      %{"session" => %{"email" => "foo@bar.com", "password" => "azerty", "remember" => "true"}}
  """
  end
  @spec session_params_with_rememberme(attrs :: Haytni.params) :: Haytni.params
  defp session_params_with_rememberme(attrs \\ %{}) do
    attrs
    |> session_params_without_rememberme()
    |> put_in(~W[session remember], "true")
  end

  describe "Haytni.RememberablePlugin.on_successful_authentication/6 (callback)" do
    setup do
      [
        user: user_fixture(),
        config: @plugin.build_config(),
      ]
    end

    test "do nothing (no rememberme cookie is created) if rememberme checkbox is not checked", %{conn: conn, config: config, user: user} do
      assert {new_conn, multi, []} = @plugin.on_successful_authentication(%{conn | params: session_params_without_rememberme()}, user, Ecto.Multi.new(), Keyword.new(), @stack, config)
      assert [] == Ecto.Multi.to_list(multi)
      refute_cookie_presence(new_conn, config.remember_cookie_name)
    end

    test "if rememberme checkbox is checked ensures a new token is generated and sent", %{conn: conn, config: config, user: user} do
      assert {new_conn, multi, _changes} = @plugin.on_successful_authentication(%{conn | params: session_params_with_rememberme()}, user, Ecto.Multi.new(), Keyword.new(), @stack, config)
      assert [{:rememberable_token, {:insert, changeset = %Ecto.Changeset{}, []}}] = Ecto.Multi.to_list(multi)
      assert_rememberme_presence(new_conn, config, Haytni.Token.url_encode(changeset.data))
    end
  end
end
