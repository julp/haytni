defmodule HaytniTestWeb.Router do
  use HaytniTestWeb, :router
  require HaytniTestWeb.Haytni
  require HaytniTestWeb.Haytni2

  pipeline :browser do
    plug :accepts, ~W[html]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  scope "/" do
    pipe_through [:browser, HaytniTestWeb.Haytni]

    HaytniTestWeb.Haytni.routes()
  end

  scope "/admin", as: :admin do
    pipe_through [:browser, HaytniTestWeb.Haytni2]

    HaytniTestWeb.Haytni2.routes()
  end
end
