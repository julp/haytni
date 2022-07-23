<%= if Haytni.AuthenticablePlugin in plugins do %>
defmodule <%= inspect base_module %>.Haytni.Helpers do
  def expassword_options(:test, algo = ExPassword.Bcrypt), do: [hashing_method: algo, hashing_options: %{cost: 4}]
  def expassword_options(_env, algo = ExPassword.Bcrypt), do: [hashing_method: algo, hashing_options: %{cost: 10}]
  def expassword_options(:test, algo = ExPassword.Argon2), do: [hashing_method: algo, hashing_options: %{memory_cost: 256, version: 0x13, threads: 1, time_cost: 2, type: :argon2id}]
  def expassword_options(_env, algo = ExPassword.Argon2), do: [hashing_method: algo, hashing_options: %{memory_cost: 131072, version: 0x13, threads: 2, time_cost: 4, type: :argon2id}]
end
<% end %>

defmodule <%= inspect base_module %>.Haytni do
  use Haytni, otp_app: <%= inspect otp_app %>

  <%= if Haytni.AuthenticablePlugin in plugins do %>
    import <%= inspect base_module %>.Haytni.Helpers
  <% end %>

  <%= for plugin <- plugins do %>
    stack <%= inspect plugin %><%= if plugin == Haytni.AuthenticablePlugin do %>, expassword_options(Mix.env(), ExPassword.Bcrypt)<% end %>
  <% end %>
end
