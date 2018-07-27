defmodule Haytni.Config do

  @application :haytni

  defmacro __using__(defaults \\ []) do
    defaults
    |> Enum.map(
      fn {key, default} ->
        quote do
          def unquote(key)(default \\ unquote(default)) do
            Haytni.fetch_config(unquote(key), default)
          end
        end
      end
    )
  end

  def _fetch_config(key, default \\ nil) do
    case Application.get_env(@application, key, default) do
      {:system, variable} ->
        System.get_env(variable)
      value ->
        value
    end
  end

end
