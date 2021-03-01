defmodule Haytni.Tokenable do
  @doc ~S"""
  TODO (doc)
  """
  @callback token_context(Haytni.nilable(String.t)) :: String.t

  @doc ~S"""
  TODO (doc)
  """
  @callback expired_tokens_query(config :: Haytni.config) :: String.t

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      @behaviour unquote(__MODULE__)
    end
  end
end
