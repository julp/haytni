defmodule Haytni.Callbacks.UserQueryTest do
  use Haytni.DataCase, async: true

  @doc false
  defmodule DummyPlugin do
    use Haytni.Tokenable

    def token_context(nil), do: "dummy"

    def expired_tokens_query(query, _config), do: query
  end

  describe "Haytni.Callbacks.user_query/1" do
    setup do
      language_fixture("English")
      language = language_fixture("Français")
      [
        user: user_fixture(language_id: language.id, firstname: "Sebastian"),
      ]
    end

    test "Haytni.get_user/2", %{user: user} do
      %HaytniTest.User{language: %HaytniTest.Language{}} = Haytni.get_user(HaytniTestWeb.Haytni, user.id)
    end

    test "Haytni.get_user_by/2", %{user: user} do
      %HaytniTest.User{language: %HaytniTest.Language{}} = Haytni.get_user_by(HaytniTestWeb.Haytni, firstname: user.firstname)
    end

    test "Haytni.Token.user_from_token_with_mail_match/4", %{user: user} do
      token =
        user
        |> token_fixture(DummyPlugin)

      %HaytniTest.User{language: %HaytniTest.Language{}} = Haytni.Token.user_from_token_with_mail_match(HaytniTestWeb.Haytni, token.token, DummyPlugin.token_context(nil), 3600)
    end
  end
end
