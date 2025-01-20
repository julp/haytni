defmodule HaytniWeb.RolablePlugin.RoleRestrictedPlug do
  @moduledoc """
  A plug to add restricted access based on roles.

  Usage examples (for your router):

  ```elixir
  pipeline :restricted_to_admin do
    plug #{inspect(__MODULE__)}, "admin"
  end

  pipeline :restricted_to_foo_and_bar do
    plug #{inspect(__MODULE__)}, ~W[foo bar]
  end

  scope ... do
    pipe_through ~W[browser restricted_to_admin]a # <= the most important line (with :restricted_to_admin **after** :browser)

    # your restricted routes to "admin" role
  end

  scope ... do
    pipe_through ~W[browser restricted_to_foo_and_bar]a # <= the most important line (with :restricted_to_foo_and_bar **after** :browser)

    # your restricted routes to roles "foo" and (exclusive) "bar"
  end
  ```

  Could also be directly used in a controller:

  ```elixir
  defmodule YourAppWeb.RestrictedToFooAndBarController do
    use YourAppWeb, :controller

    plug #{inspect(__MODULE__)}, ~W[foo bar]

    # ...
  end
  ```
  """

  @behaviour Plug

  use Gettext, backend: Haytni.Gettext

  @impl Plug
  def init(roles) do
    roles
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> MapSet.new()
  end

  @impl Plug
  def call(conn = %Plug.Conn{assigns: %{current_user: current_user}}, required_roles) do
    if Haytni.RolablePlugin.has_role?(current_user, required_roles) do
      conn
    else
      conn
      |> Phoenix.Controller.put_flash(:error, dgettext("haytni", "Access restricted"))
      |> Phoenix.Controller.redirect(to: "/")
      |> Plug.Conn.halt()
    end
  end
end
