defmodule HaytniWeb do
  @moduledoc false

  @doc false
  def controller do
    quote do
      use Phoenix.Controller, namespace: unquote(__MODULE__)
      import Plug.Conn
    end
  end

  @doc false
  defmacro __using__(which)
    when is_atom(which)
  do
    apply(__MODULE__, which, [])
  end
end
