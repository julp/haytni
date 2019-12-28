defmodule Haytni.Token do
  @moduledoc ~S"""
  This module handles generation of tokens for the use of Haytni's plugins.
  """

  @doc ~S"""
  Generates a token of *length* long
  """
  def generate(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
end
