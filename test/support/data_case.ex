defmodule Haytni.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias HaytniTest.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Haytni.DataCase
      import Haytni.TestHelpers 
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
