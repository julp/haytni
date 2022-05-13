defmodule Haytni.Callbacks do
  @moduledoc ~S"""
  This module defines the optional callbacks that a Haytni stack can redefine (override).
  """

  @doc ~S"""
  Override the internal queries used to load the current user. It is particularly useful to load data tied to users.

  Example to load user's roles:

      @impl Haytni.Callbacks
      def user_query(query) do
        query
        |> preload([:roles])
      end
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
