defmodule HaytniWeb.ChannelCase do
  defmacro __using__(options \\ [])

  use ExUnit.CaseTemplate

  defmacro __using__(options) do
    {options, quoted} = Haytni.Case.haytni_common(options)
    quote do
      unquote(super(options))

      # Import conveniences for testing with channels
      import Phoenix.ChannelTest
      import Haytni.TestHelpers

      unquote(quoted)
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HaytniTest.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(HaytniTest.Repo, {:shared, self()})
    end

    :ok
  end
end
