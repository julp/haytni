defmodule Haytni.DataCase do
  defmacro __using__(options \\ [])

  use ExUnit.CaseTemplate

  defmacro __using__(options) do
    {options, quoted} = Haytni.Case.haytni_common(options)
    quote do
      unquote(super(options))

      import Ecto
      import Ecto.Changeset
      import unquote(__MODULE__)
      import Haytni.TestHelpers
      alias Haytni.Params

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

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
