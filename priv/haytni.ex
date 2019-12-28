defmodule <%= inspect base_module %>.Haytni do
  use Haytni, otp_app: <%= inspect otp_app %>

  <%= for plugin <- plugins do %>
  stack <%= inspect plugin %>
  <% end %>
end
