defmodule Haytni.Callbacks do
  @moduledoc ~S"""
  TODO
  """

  @doc ~S"""
  TODO
  """
  @callback user_query(query :: Ecto.Queryable.t) :: Ecto.Queryable.t

  defmacro __using__(_options) do
    quote do
      @behaviour unquote(__MODULE__)

      @impl unquote(__MODULE__)
      def user_query(query), do: query

      defoverridable [
        user_query: 1,
      ]
    end
  end
end
