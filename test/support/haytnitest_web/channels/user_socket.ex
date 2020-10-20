defmodule HaytniTestWeb.UserSocket do
  use Phoenix.Socket

  # channel "room:*", HaytniTestWeb.RoomChannel

  @impl Phoenix.Socket
  def connect(params, socket, connect_info) do
    Haytni.LiveViewPlugin.connect(HaytniTest.Haytni, params, socket, connect_info)
  end

  @impl Phoenix.Socket
  def id(socket) do
    "user_socket:" <> socket.assigns.user_id
  end
end
