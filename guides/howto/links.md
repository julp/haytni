# How to generate (non-)connected links to users

In your templates, to know if the current user is currently authenticated, you just need to test the `@current_user` assign which is automaticaly set for you (if your *scope* is `:admin`, for exemple, use `@current_admin` instead of `@current_user`). A typical use case is to handle the links register + login vs profile + logout:

```heex
<nav>
  <ul>
    <%= if @current_user do %>
      <%# if the user is connected, display links to edit his profile and logout %>
      <li>
        <%= link YourAppWeb.Gettext.dgettext("your_app", "Profile"), to: Routes.haytni_user_registration_path(@conn, :edit) %>
      </li>
      <li>
        <%= link YourAppWeb.Gettext.dgettext("your_app", "Logout"), to: Routes.haytni_user_session_path(@conn, :delete), method: :delete %>
      </li>
    <% else %>
      <%# if the user is not connected, display links to connect or register %>
      <li>
        <%= link Haytni.Gettext.dgettext("haytni", "Sign in"), to: Routes.haytni_user_session_path(@conn, :new) %>
      </li>
      <li>
        <%= link Haytni.Gettext.dgettext("haytni", "Sign up"), to: Routes.haytni_user_registration_path(@conn, :new) %>
      </li>
    <% end %>
  </ul>
</nav>
```
