defmodule Haytni.Params do
  @moduledoc ~S"""
  Convenient functions to build the *params* Map (parameters for the HTTP request) in tests
  """

  defp coalesce(a, nil), do: a
  defp coalesce(_a, b), do: b

  defp to_stringified_map(struct = %_{}) do
    struct
    |> Map.from_struct()
    |> to_stringified_map()
  end

  defp to_stringified_map(other) do
    Enum.into(other, %{}, fn {k, v} -> {to_string(k), v} end)
  end

  @doc ~S"""
  Creates parameters (a map of string as keys and values) by merging *attrs* into *defaults*.

  NOTES:

    * *defaults* has to contain all the necessary keys because, in order to accept struct
      as *attrs* the extra keys of *attrs* are dropped
    * all keys are stringified for convenience/reduce boilerplate
    * if a value in *attrs* is a function (of 1-arity), it will be called with the corresponding
      value of *defaults* to set the final value
    * `nil` values from a struct are "safely" ignored
  """
  @spec create(defaults :: Enumerable | struct, attrs :: Enumerable | struct) :: %{String.t => String.t}
  def create(defaults, attrs \\ %{}) do
    defaults = to_stringified_map(defaults)
    attrs = attrs
    |> to_stringified_map()
    |> Map.take(Map.keys(defaults))

    defaults
    |> Map.merge(attrs, fn _k, v1, v2 -> coalesce(v1, v2) end)
    |> Enum.into(
      %{},
      fn {k, v} ->
        k = to_string(k)
        v = if is_function(v, 1) do
          v.(Map.fetch!(defaults, k))
        else
          v
        end

        {k, v}
      end
    )
  end

  @doc """
  Adds the confirmation *keys* to the map *params* by copying the values of the given keys under the same
  suffixed by "_confirmation".

  Example:

      iex> #{__MODULE__}.confirm(%{"email" => "foo@bar.com", "password" => "azerty", ~W[password]a}
      %{"email" => "foo@bar.com", "password" => "azerty", "password_confirmation" => "azerty"}
  """
  @spec confirm(params :: %{String.t => String.t}, keys :: [atom | String.t]) :: %{String.t => String.t}
  def confirm(params, keys) do
    keys
    |> Enum.reduce(
      params,
      fn key, params_as_acc ->
        Map.put(params_as_acc, "#{key}_confirmation", Map.fetch!(params_as_acc, to_string(key)))
      end
    )
  end

  @doc """
  Wraps *params* in an other Map with the stringified *key* as key

  Example:

      iex> #{__MODULE__}.wrap(%{"email" => %{"email" => "foo@bar.com", "password" => "azerty"}}, :session)
      %{"session" => %{"email" => "foo@bar.com", "password" => "azerty"}}
  """
  @spec wrap(params :: %{String.t => String.t}, key :: atom | String.t) :: %{required(String.t) => %{optional(String.t) => String.t}}
  def wrap(params, key) do
    %{to_string(key) => params}
  end
end
