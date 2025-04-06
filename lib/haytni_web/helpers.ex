defmodule HaytniWeb.Helpers do
  @moduledoc false

  def put_view(conn, module, view_suffix) do
    view_module =
      [
        module.web_module(),
        :Haytni,
        module.scope() |> to_string() |> Phoenix.Naming.camelize(),
        view_suffix,
      ]
      |> Module.concat()
      |> Code.ensure_compiled()
      |> case do
        {:module, module} ->
          module
        _ ->
          Module.concat([module.web_module(), :Haytni, view_suffix])
      end

    conn
    |> Phoenix.Controller.put_view(view_module)
  end

  @doc ~S"""
  Add and set the HTTP header *x-suspicious-activity* to the value *1* (as string) to the HTTP response
  in order to allow a proxy, in front of your application, to take action in case of repeated suspicious
  activity from a same origin.
  """
  def set_suspicious_activity(conn) do
    conn
    |> Plug.Conn.put_resp_header("x-suspicious-activity", "1")
  end

  defmacro __using__(options) do
    quote bind_quoted: [options: options] do
      view_suffix =
        __MODULE__
        |> Module.split()
        |> List.last()
        |> Phoenix.Naming.unsuffix("Controller")
        |> Kernel.<>("HTML")

      {plugin, extra_args} =
        case options do
          {plugin, :with_current_user} ->
            {plugin, [quote(do: conn.assigns[module.scoped_assign()])]}
          plugin when is_atom(plugin) ->
            {plugin, []}
        end

      def action(conn, _) do
        module = Haytni.fetch_module_from_conn!(conn)
        config = module.fetch_config(unquote(plugin))

        conn =
          conn
          |> assign(:module, module)
          |> assign(:config, config)
          |> put_layout(module.layout())
          |> HaytniWeb.Helpers.put_view(module, unquote(view_suffix))

        args = [conn, conn.params, unquote_splicing(extra_args), module, config]
        apply(__MODULE__, action_name(conn), args)
      end
    end
  end
end
