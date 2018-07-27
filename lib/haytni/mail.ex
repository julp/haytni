defmodule Haytni.Mail do
  import Bamboo.Email

  def assign(email = %Bamboo.Email{assigns: assigns}, key, value)
    when is_atom(key)
  do
    %{email | assigns: Map.put(assigns, key, value)}
  end

  def put_view(email = %Bamboo.Email{}, view) do
    email
    |> put_private(:view, view)
  end

  def put_text_template(email = %Bamboo.Email{private: %{view: view}}, template)
    when not is_nil(view)
  do
    email
    |> text_body(Phoenix.View.render_to_string(view, template, email.assigns))
  end

  def put_html_template(email = %Bamboo.Email{private: %{view: view}}, template)
    when not is_nil(view)
  do
    email
    |> html_body(Phoenix.View.render_to_string(view, template, email.assigns))
  end
end
