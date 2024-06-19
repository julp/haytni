defmodule HaytniWeb.EmailCase do
  defmacro __using__(options \\ [])

  use ExUnit.CaseTemplate

  defmacro __using__(options) do
    {options, quoted} = Haytni.Case.haytni_common(options)
    quote do
      unquote(super(options))

      import unquote(__MODULE__)
      import Haytni.TestHelpers
      import Haytni.Mailer.TestAdapter

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
