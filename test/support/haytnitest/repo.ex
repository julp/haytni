defmodule HaytniTest.Repo do
  use Ecto.Repo,
    otp_app: :haytni,
    adapter: Ecto.Adapters.Postgres
    #adapter: Ecto.Adapters.MyXQL
end
