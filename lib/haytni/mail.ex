defmodule Haytni.Mail do
  @moduledoc ~S"""
  An intermediate to easily create a Bamboo email in a Phoenix way.

  In fact, this module is similar to `Bamboo.Phoenix` but I encountered some limitations
  and troubles to deal with views/templates path.
  """

  @doc ~S"""
  Sets an assign for the email. These will be available when rendering the email.
  """
  @spec assign(email :: Bamboo.Email.t, key :: atom, value :: any) :: Bamboo.Email.t
  def assign(email = %Bamboo.Email{assigns: assigns}, key, value)
    when is_atom(key)
  do
    %{email | assigns: Map.put(assigns, key, value)}
  end

  @doc ~S"""
  Stores the view for rendering the email.
  """
  @spec put_view(email :: Bamboo.Email.t, view :: module) :: Bamboo.Email.t
  def put_view(email = %Bamboo.Email{}, view) do
    email
    |> Bamboo.Email.put_private(:view, view)
  end

  @doc ~S"""
  Set and infer the full name of the view for email from *module* and its scope.

  Example: if `view_suffix = "Email.NewLoginNotification"` and scope associated to *module* is `:admin`
  the view module is set to `YourAppWeb.Admin.Email.NewLoginNotification` if it exists else fallback to
  `YourAppWeb.Email.NewLoginNotification`.
  """
  @spec put_view(email :: Bamboo.Email.t, module :: module, view_suffix :: atom | String.t) :: Bamboo.Email.t
  def put_view(email = %Bamboo.Email{}, module, view_suffix) do
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

    email
    |> put_view(view_module)
  end

  @doc ~S"""
  Sets the template for when rendering the email as plain text.

  NOTE: the view (see `put_view/2`) has to be set prior to a call to `put_text_template/2`.
  """
  @spec put_text_template(email :: Bamboo.Email.t, template :: String.t) :: Bamboo.Email.t
  def put_text_template(email = %Bamboo.Email{private: %{view: view}}, template)
    when not is_nil(view)
  do
    email
    |> Bamboo.Email.text_body(Phoenix.View.render_to_string(view, template, email.assigns))
  end

  @doc ~S"""
  Same as `put_text_template/2` but for rendering the email as HTML.

  NOTE: the view (see `put_view/2`) has to be set prior to a call to `put_html_template/2`.
  """
  @spec put_html_template(email :: Bamboo.Email.t, template :: String.t) :: Bamboo.Email.t
  def put_html_template(email = %Bamboo.Email{private: %{view: view}}, template)
    when not is_nil(view)
  do
    email
    |> Bamboo.Email.html_body(Phoenix.View.render_to_string(view, template, email.assigns))
  end
end
