defmodule Haytni.ViewAndLayoutPlug do
  import Phoenix.Controller

  def init(options) do
    options
  end

  def call(conn, view_suffix) do
    conn
    |> put_layout(Haytni.layout())
    |> put_view(Module.concat([Haytni.web_module(), :Haytni, view_suffix]))
  end
end
