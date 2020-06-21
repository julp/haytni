# How to realize extra operations with Invitable

## List invitations sent by the current user

We first need to add a route for that, so in your router, add the following:

```elixir
# lib/your_app_web/router.ex

resources "/invitations", YourAppWeb.InvitationController, only: ~W[index]a
```

(I voluntarily don't use `get "/invitations", YourAppWeb.InvitationController` to have easier to add other actions)

Next, in one of your contexts or a new one, add a function to get the invitations of a user:

```elixir
defmodule YourApp.Accounts do
  import Ecto.Query

  alias YourApp.Repo
  import Haytni.InvitablePlugin.QueryHelpers

  # ...

  @spec list_invitations(user :: YourApp.user) :: [Haytni.InvitablePlugin.invitation]
  def list_invitations(user = %YourApp.User{}) do
    user
    |> invitations_from_user()
    |> preload([:accepter])
    |> order_by([desc: :sent_at])
    |> Repo.all()
  end
end
```

So this way, you can easily add any filter (accepted or not, expired or not and so on) as pagination at any time.

Finaly, we'll have to write this controller and *index* action:

```elixir
# lib/your_app_web/controllers/invitation_controller.ex

defmodule YourAppWeb.InvitationController do
  use YourAppWeb, :controller

  def index(conn, _params) do
    if current_user = conn.assigns[:current_user] do
      conn
      |> assign(:invitations, Accounts.list_invitations(current_user))
      |> render(:index)
    else
      {:error, :forbidden} # to be handled by an Action Fallback
    end
  end
end
```

If you need a starting point for the corresponding template, here it is:

```eex
# lib/your_app_web/templates/invitation/index.html.eex

<%= if Enum.any?(@invitations) do %>
  <table>
    <thead>
      <tr>
        <th><%= dgettext("myapp", "Sent at") %></th>
        <th><%= dgettext("myapp", "Sent to") %></th>
        <th><%= dgettext("myapp", "Accepted at") %></th>
        <th><%= dgettext("myapp", "Accepted by") %></th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <%= for invitation <- @invitations do %>
        <tr>
          <td><%= invitation.sent_at %></td>
          <td><%= invitation.sent_to %></td>
          <td><%= if is_nil(invitation.accepted_at), do: "-", else: invitation.accepted_at %></td>
          <td><%= if is_nil(invitation.accepted_by), do: "-", else: invitation.accepter.name %></td>
          <td><%= if is_nil(invitation.accepted_by), do: link(dgettext("myapp", "Revoke"), to: Routes.invitation_path(@conn, :delete, invitation), method: :delete) %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
<% else %>
  <p><%= dgettext("myapp", "You have not send any invitation for now.") %></p>
<% end %>

<p>
  <%= link dgettext("myapp", "Do you have a friend you want to invite?"), to: Routes.haytni_user_invitation_path(@conn, :new) %>
</p>
```

## Delete a non-accepted invitation

First, in your router, add a *delete* route:

```elixir
# lib/your_app_web/router.ex

resources "/invitations", YourAppWeb.InvitationController, only: ~W[delete]a
```

Then, in one of your contexts or a new one, write a revoke_invitation like this one:

```elixir
defmodule YourApp.Accounts do
  import Ecto.Query

  alias YourApp.Repo
  import Haytni.InvitablePlugin.QueryHelpers

  # ...

  @spec revoke_invitation(user :: YourApp.User, id :: any) :: boolean
  def revoke_invitation(user = %YourApp.User{}, id)
    when not is_nil(id)
  do
    {count, nil} =
      user
      |> invitations_from_user()
      |> and_where_not_accepted()
      |> and_where_id_equals(id)
      |> Repo.delete_all()

    1 == count
  end
end
```

Lastly, write the delete action of your invitation controller based on this model:

```elixir
# lib/your_app_web/controllers/invitation_controller.ex

defmodule YourAppWeb.InvitationController do
  use YourAppWeb, :controller

  def delete(conn, %{"id" => invitation_id}) do
    if current_user = conn.assigns[:current_user] do
      Haytni.InvitablePlugin.revoke_invitation(current_user, invitation_id)

      conn
      |> put_flash(:info, "Invitation has been successfully revoked")
      |> redirect(to: "/")
      |> halt()
    else
      {:error, :forbidden} # to be handled by an Action Fallback
    end
  end
end
```
