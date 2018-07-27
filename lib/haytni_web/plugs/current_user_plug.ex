defmodule Haytni.CurrentUserPlug do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, options) do
    scope = Keyword.get(options, :scope, :user)
    {conn, user} = Haytni.find_user(conn)
    assign(conn, :"current_#{scope}", user)
  end
end
