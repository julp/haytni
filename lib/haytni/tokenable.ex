defmodule Haytni.Tokenable do
  @doc ~S"""
  Get the applicable context
  """
  @callback token_context(Haytni.nilable(String.t)) :: String.t

  @doc ~S"""
  Callback to build the query to purge expired tokens
  """
  @callback expired_tokens_query(query :: Ecto.Queryable.t, config :: Haytni.config) :: Ecto.Query.t

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      @behaviour unquote(__MODULE__)
    end
  end
end
