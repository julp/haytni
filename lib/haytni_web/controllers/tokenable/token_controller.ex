defmodule HaytniWeb.Tokenable.TokenController do
  @moduledoc false

  use HaytniWeb, :controller
  use HaytniWeb.Helpers, {Haytni.LiveViewPlugin, :with_current_user}

  def create(conn, _params, nil, _module, _config) do
    conn
    |> put_status(:forbidden)
    |> json(nil)
    |> halt()
  end

  def create(conn, _params, current_user, module, _config) do
    {:ok, token} =
      current_user
      |> Haytni.Token.build_and_assoc_token(current_user.email, Haytni.LiveViewPlugin.token_context())
      |> module.repo().insert()

    conn
    |> put_resp_header("cache-control", "no-store")
    |> json(Haytni.LiveViewPlugin.encode_token(conn, token))
  end
end
