defmodule HaytniTestWeb.HaytniEmpty do
  use Haytni, otp_app: :haytni_test

  @impl Haytni.Callbacks
  def user_query(query) do
    import Ecto.Query

    from(
      query,
      where: false
    )
  end
end
