defmodule Haytni.Rememberable.OnSuccessfulAuthentificationTest do
  use HaytniWeb.ConnCase, async: true

  if false do
  @doc """
  Creates the parameters to simulate a "permanent" sign in action.

  Example:

      iex> #{__MODULE__}.session_params_with_rememberme(%{"email" => "foo@bar.com", "password" => "azerty"})
      %{"session" => %{"email" => "foo@bar.com", "password" => "azerty", "remember" => "checked"}}
  """
  end
  @spec session_params_with_rememberme(attrs :: Haytni.params) :: Haytni.params
  defp session_params_with_rememberme(attrs \\ %{}) do
    attrs
    |> session_params_without_rememberme()
    |> put_in(~W[session remember], "checked")
  end

  describe "Haytni.Rememberable.on_successful_authentication/6 (callback)" do
    setup do
      config = Haytni.RememberablePlugin.build_config()
      user_without_token = %HaytniTest.User{remember_token: nil, remember_created_at: nil}
      user_with_valid_token = %HaytniTest.User{remember_token: "rOlFVqQG0CLB", remember_created_at: Haytni.Helpers.now()}
      user_with_expired_token = %HaytniTest.User{remember_token: "071pviHFiiil", remember_created_at: seconds_ago(config.remember_for + 1)}

      [
        config: config,
        user_without_token: user_without_token,
        user_with_valid_token: user_with_valid_token,
        user_with_expired_token: user_with_expired_token,
      ]
    end

    test "do nothing (no rememberme cookie is created) if rememberme checkbox is not checked", ctxt do
      for user <- [ctxt.user_without_token, ctxt.user_with_expired_token, ctxt.user_with_valid_token] do
        assert {new_conn, multi, []} = Haytni.RememberablePlugin.on_successful_authentication(%{ctxt.conn | params: session_params_without_rememberme()}, user, Ecto.Multi.new(), Keyword.new(), HaytniTestWeb.Haytni, ctxt.config)
        assert [] == Ecto.Multi.to_list(multi)
        refute_cookie_presence(new_conn, ctxt.config.remember_cookie_name)
      end
    end

    if false do
      test "if rememberme checkbox is checked but current user rememberme token is expired, generate (and send) a new one", ctxt do
        assert {new_conn, multi, changes} = Haytni.RememberablePlugin.on_successful_authentication(%{ctxt.conn | params: session_params_with_rememberme()}, ctxt.user_with_expired_token, Ecto.Multi.new(), Keyword.new(), HaytniTestWeb.Haytni, ctxt.config)
        assert [] == Ecto.Multi.to_list(multi)
        # NOTE/TODO: it won't work because RememberablePlugin doesn't check the value of the column remember_created_at,
        # it counts on Phoenix.Token.verify for expiration but we have no way to override time generation of the token
        # when calling Phoenix.Token.sign
        assert Keyword.keys(changes) == ~W[remember_token remember_created_at]a
        assert_rememberme_presence(new_conn, ctxt.config, changes[:remember_token])
      end
    end

    test "if rememberme checkbox is checked but current user rememberme token is still valid, send it as rememberme cookie", ctxt do
      assert {new_conn, multi, []} = Haytni.RememberablePlugin.on_successful_authentication(%{ctxt.conn | params: session_params_with_rememberme()}, ctxt.user_with_valid_token, Ecto.Multi.new(), Keyword.new(), HaytniTestWeb.Haytni, ctxt.config)
      assert [] == Ecto.Multi.to_list(multi)
      assert_rememberme_presence(new_conn, ctxt.config, ctxt.user_with_valid_token.remember_token)
    end

    test "if rememberme checkbox is checked but current user doesn't have a rememberme token, generate (and send) a new token", ctxt do
      assert {new_conn, multi, changes} = Haytni.RememberablePlugin.on_successful_authentication(%{ctxt.conn | params: session_params_with_rememberme()}, ctxt.user_without_token, Ecto.Multi.new(), Keyword.new(), HaytniTestWeb.Haytni, ctxt.config)
      assert [] == Ecto.Multi.to_list(multi)
      assert Keyword.keys(changes) == ~W[remember_token remember_created_at]a
      assert_rememberme_presence(new_conn, ctxt.config, changes[:remember_token])
    end
  end
end
