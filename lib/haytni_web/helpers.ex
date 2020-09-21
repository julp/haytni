defmodule HaytniWeb.Helpers do
  @moduledoc false

  def put_view(conn, module, view_suffix) do
    view_module = Module.concat([module.web_module(), :Haytni, Phoenix.Naming.camelize(to_string(module.scope())), view_suffix])
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

  defmacro __using__(options) do
    quote bind_quoted: [options: options] do
      view_suffix =
        __MODULE__
        |> Module.split()
        |> List.last()
        |> Phoenix.Naming.unsuffix("Controller")
        |> Kernel.<>("View")

      {plugin, extra_args} = case options do
        {plugin, :with_current_user} ->
          {plugin, [quote(do: conn.assigns[:"current_#{module.scope()}"])]}
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
