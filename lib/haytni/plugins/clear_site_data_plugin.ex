defmodule Haytni.ClearSiteDataPlugin do
  use Haytni.Plugin

  @clear_site_data_header_name "clear-site-data"
  @possible_values ~W[cache cookies storage executionContexts *]

  @default_login []
  @default_logout @possible_values

  @moduledoc """
  The only purpose of this plugin is to handle the HTTP Clear-Site-Data header for you.

  Fields: none

  Configuration:

    * `login` (default: `#{inspect(@default_login)}`): values, as a list of binaries, to set to #{@clear_site_data_header_name} header at login
    * `logout` (default: `#{inspect(@default_logout)}`): same for logout

          stack #{inspect(__MODULE__)},
            login: [],
            logout: :all

  Possible values are: #{inspect(@possible_values)} or the atom `:all` to include all of them.

  Routes: none
  """

  defstruct [
    login: @default_login,
    logout: @default_logout,
  ]

  @type t :: %__MODULE__{
    login: [String.t],
    logout: [String.t],
  }

  defp check_clear_site_data_values(nil, default), do: default
  defp check_clear_site_data_values(:all, _default), do: @possible_values
  defp check_clear_site_data_values(values, _default)
    when is_list(values)
  do
    unexpected = Enum.find(values, fn v -> not is_binary(v) or v not in @possible_values end)
    if is_nil(unexpected) do
      values
    else
      raise ArgumentError, """
      Invalid value: #{inspect(unexpected)} for the HTTP header #{@clear_site_data_header_name} has been found.

      Expected values are: #{Enum.join(@possible_values, ", ")}
      """
    end
  end

  @doc false # for tests
  @spec possible_values() :: [String.t]
  def possible_values do
    @possible_values
  end

  @doc false # for tests
  @spec clear_site_data_header_name() :: String.t
  def clear_site_data_header_name do
    @clear_site_data_header_name
  end

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %__MODULE__{
      login: options[:login] |> check_clear_site_data_values(@default_login),
      logout: options[:logout] |> check_clear_site_data_values(@default_logout),
    }
  end

  defp put_clear_site_data_resp_header(conn, []), do: conn
  defp put_clear_site_data_resp_header(conn, values) do
    Plug.Conn.put_resp_header(conn, @clear_site_data_header_name, "\"" <> Enum.join(values, "\", \"") <> "\"")
  end

  @impl Haytni.Plugin
  def on_logout(conn, _module, config) do
    put_clear_site_data_resp_header(conn, config.logout)
  end

  @impl Haytni.Plugin
  def on_successful_authentication(conn, _user, multi, keywords, _module, config) do
    {put_clear_site_data_resp_header(conn, config.login), multi, keywords}
  end
end
