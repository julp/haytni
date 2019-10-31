defmodule Haytni.CurrentUserPlug do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn = %Plug.Conn{assigns: %{current_user: current_user}}, _options)
    when nil != current_user
  do
    conn
  end

  def call(conn, _options) do
    {conn, user} = Haytni.find_user(conn)
    assign(conn, :current_user, user)
  end
end
