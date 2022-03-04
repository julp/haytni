# How to realize extra operations with Trackable

## List (all) connections of the current user

In your "user" context:

```elixir
  alias YourApp.Repo

  def user_connections(user) do
    user
    |> Haytni.TrackablePlugin.QueryHelpers.connections_from_user()
    |> Repo.all() # paginate if you want/like
  end
```

In your controller:

```elixir
  def index(conn, _params) do
    if current_user = conn.assigns[:current_user] do
      conn
      # ...
      |> assign(:connections, user_connections(current_user))
      |> render(:index)
    else
      {:error, :forbidden}
    end
  end
```

Part of the template:

```heex
<ul>
  <%= for connection <- @connections do %>
    <li><%= c.ip %> (<%= c.inserted_at %>)</li>
  <% end %>
</ul>
```

## Search who used an IP address

First, to have easier to handle the form for search and maintain/enhance it, we will introduce a schema less module called `YourApp.Admin.IpSearch`:

```elixir
# lib/your_app/admin/ipsearch.ex

defmodule YourApp.Admin.IpSearch do
  import Ecto.Changeset

  @types %{
    ip: :string,
    first: :utc_datetime,
    last: :utc_datetime,
  }

  @attributes Map.keys(@types)
  defstruct @attributes

  @required ~W[ip]a
  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    {struct, @types}
    |> Ecto.Changeset.cast(params, @attributes)
    |> validate_required(@required)
    |> validate_ipaddress(:ip)
  end
end
```

Create an admin context or reuse one where we will implement the functions `change_ipsearch/[01]`, `create_ipsearch/1`, `find_by_ip/1`:

```elixir
# lib/your_app/admin/admin.ex

defmodule YourApp.Admin do
  import Ecto.Query, warn: false
  alias YourApp.Repo

  alias YourApp.Admin.IpSearch

  def change_ipsearch do
    change_ipsearch(%IpSearch{})
  end

  def change_ipsearch(%IpSearch{} = search) do
    IpSearch.changeset(search, %{})
  end

  def create_ipsearch(attrs \\ %{}) do
    %IpSearch{}
    |> IpSearch.changeset(attrs)
    |> Ecto.Changeset.apply_action(:insert)
  end

  def find_by_ip(search = %IpSearch{}) do
    import Haytni.TrackablePlugin.QueryHelpers

    %User{}
    |> connections_from_all()
    |> and_where_ip_equals(search.ip)
    |> and_where_date_between(search.first, search.last)
    |> preload([:user])
    |> order_by([desc: :inserted_at])
    |> Repo.all()
  end
end
```

Then here is the controller:

```elixir
# lib/your_app_web/controllers/admin/ip_search_controller.ex

defmodule YourAppWeb.Admin.IpSearchController do
  use YourAppWeb, :controller

  alias YourApp.Repo
  alias YourApp.User
  alias YourApp.Admin

  defp render_new(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> assign(:changeset, changeset)
    |> render(:new)
  end

  def new(conn, _params) do
    render_new(conn, Admin.change_ipsearch())
  end

  def create(conn, params) do
    search_params
    |> Admin.create_ipsearch()
    |> case do
      {:ok, search} ->
        conn
        |> assign(:search, search)
        |> assign(:results, Admin.find_by_ip(search))
        |> render(:create)
      {:error, changeset} ->
        render_new(conn, changeset)
    end
  end
end
```

The `new` template:

```heex
# lib/your_app_web/templates/admin/ip_search/new.html.heex

<%= form_for @changeset, Routes.admin_ip_search_path(@conn, :create), [as: :search], fn f ->  %>
  <div class="form-group">
    <%= label f, :ip %>
    <%= text_input f, :ip %>
    <%= error_tag f, :ip %>
  </div>
  <div class="form-group">
    <%= label f, :first %>
    <%= datetime_select f, :first %>
    <%= error_tag f, :first %>
  </div>
  <div class="form-group">
    <%= label f, :last %>
    <%= datetime_select f, :last %>
    <%= error_tag f, :last %>
  </div>
  <br/>
  <%= submit "Search" %>
<% end %>
```

The `create` template:

```heex
# lib/your_app_web/templates/admin/ip_search/create.html.heex

<h2>Results for <b><%= @search.ip %></b></h2>

<%= if Enum.empty?(@results) do %>
  <p>This address has not been used</p>
<% else %>
  <p><%= Enum.count(@results) %> résult(s) found.</p>
  <table>
    <thead>
      <tr>
        <th>Address</th>
        <th>When</th>
        <th>User</th>
      </tr>
    </thead>
    <tbody>
      <%= for r <- @results do %>
        <tr>
          <td><%= r.ip %></td>
          <td><%= r.inserted_at %></td>
          <td><%= link r.user.name, to: Routes.admin_user_path(@conn, :show, r.user) %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
<% end %>
```

The route, according to the previous codes, would be:

```elixir
# lib/your_app_web/router.ex

defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  require YourAppWeb.Haytni

  # ...

  scope "/back", as: :admin do
    # ...

    resources "/ipsearch", YourAppWeb.Admin.IpSearchController, only: ~W[new create]a
  end
end
```

The empty view just as remainder to not forget it:

```elixir
# lib/your_app_web/views/admin/ip_search_view.ex
defmodule YourAppWeb.Admin.IpSearchView do
  use YourAppWeb, :view
end
```

NOTE: the plug to restrict access to the YourAppWeb.Admin.IpSearchController controller is not shown
