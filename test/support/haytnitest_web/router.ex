defmodule HaytniTestWeb.Router do
  use HaytniTestWeb, :router
  require HaytniTestWeb.Haytni
  require HaytniTestWeb.HaytniAdmin
  require HaytniTestWeb.HaytniCustomRoutes

  pipeline :browser do
    plug :accepts, ~W[html json]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  scope "/" do
    pipe_through [:browser, HaytniTestWeb.Haytni]

    HaytniTestWeb.Haytni.routes()
  end

  scope "/CR", as: nil do
    pipe_through [:browser, HaytniTestWeb.HaytniCustomRoutes]

    HaytniTestWeb.HaytniCustomRoutes.routes(
      login_path: "/login",
      logout_path: "/logout",
      logout_method: :get,
      unlock_path: "/unblock",
      password_path: "/secret",
      confirmation_path: "/check",
      registration_path: "/users",
      new_registration_path: "/register",
      edit_registration_path: "/profile"
    )
  end

  scope "/admin", as: :admin do
    pipe_through [:browser, HaytniTestWeb.HaytniAdmin]

    HaytniTestWeb.HaytniAdmin.routes()
  end
end
