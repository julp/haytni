# How to generate (non-)connected links to users

In your templates, to know if the current user is currently authenticated, you just need to test the `@current_user` assign which is automaticaly set for you (if your *scope* is `:admin`, for exemple, use `@current_admin` instead of `@current_user`). A typical use case is to handle the links register + login vs profile + logout:

```heex
<nav>
  <ul>
    <%= if @current_user do %>
      <%# if the user is connected, display links to edit his profile and logout %>
      <li>
        <%# Phoenix < 1.7 %>
        <%= link YourAppWeb.Gettext.dgettext("haytni", "Profile"), to: Routes.haytni_user_registration_path(@conn, :edit) %>
        <%# Phoenix >= 1.7 %>
        <.link href={Routes.haytni_user_registration_path(@conn, :edit)}>
          <%= YourAppWeb.Gettext.dgettext("haytni", "Profile") %>
        </.link>
      </li>
      <li>
        <%# Phoenix < 1.7 %>
        <%= link YourAppWeb.Gettext.dgettext("haytni", "Logout"), to: Routes.haytni_user_session_path(@conn, :delete), method: :delete %>
        <%# Phoenix >= 1.7 %>
        <.link href={Routes.haytni_user_session_path(@conn, :delete)} method="delete">
          <%= YourAppWeb.Gettext.dgettext("haytni", "Logout") %>
        </.link>
      </li>
    <% else %>
      <%# if the user is not connected, display links to connect or register %>
      <li>
        <%# Phoenix < 1.7 %>
        <%= link Haytni.Gettext.dgettext("haytni", "Sign in"), to: Routes.haytni_user_session_path(@conn, :new) %>
        <%# Phoenix >= 1.7 %>
        <.link href={Routes.haytni_user_session_path(@conn, :new)}>
          <%= YourAppWeb.Gettext.dgettext("haytni", "Sign in") %>
        </.link>
      </li>
      <li>
        <%# Phoenix < 1.7 %>
        <%= link Haytni.Gettext.dgettext("haytni", "Sign up"), to: Routes.haytni_user_registration_path(@conn, :new) %>
        <%# Phoenix >= 1.7 %>
        <.link href={Routes.haytni_user_registration_path(@conn, :new)}>
          <%= YourAppWeb.Gettext.dgettext("haytni", "Sign up") %>
        </.link>
      </li>
    <% end %>
  </ul>
</nav>
```
