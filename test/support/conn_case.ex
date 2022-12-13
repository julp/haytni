defmodule HaytniWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  defmacro __using__(options \\ [])

  use ExUnit.CaseTemplate

  defmacro __using__(options) do
    {options, quoted} = Haytni.Case.haytni_common(options)
    quote do
      unquote(super(options))

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Haytni.TestHelpers
      alias Haytni.Params
      alias HaytniTestWeb.Router.Helpers, as: Routes

      unquote(quoted)
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HaytniTest.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(HaytniTest.Repo, {:shared, self()})
    end

    conn =
      Phoenix.ConnTest.build_conn()
      |> Map.replace!(:secret_key_base, HaytniTestWeb.Endpoint.config(:secret_key_base))
      |> Plug.Conn.put_private(:phoenix_endpoint, HaytniTestWeb.Endpoint)

    [
      conn: conn,
    ]
  end
end
