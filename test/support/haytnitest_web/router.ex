defmodule HaytniTestWeb.Router do
  use HaytniTestWeb, :router
  require Haytni

  pipeline :browser do
    plug :accepts, ~W[html]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug Haytni.CurrentUserPlug
  end

  scope "/" do
    pipe_through :browser

    Haytni.routes()
  end
end
