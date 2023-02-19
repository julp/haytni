defmodule Haytni.Mail do
  @moduledoc ~S"""
  An abstraction layer to build emails before actually sending them
  """

  #@type recipient :: {String.t, String.t}

  @type t :: %__MODULE__{
    assigns: %{atom => any},
    to: any, # TODO: Haytni.user ?
    from: any,
    subject: Haytni.nilable(String.t),
    html_body: Haytni.nilable(String.t),
    text_body: Haytni.nilable(String.t),
    view: Haytni.nilable(module),
  }

  # TODO: headers ? layout ?
  #defstruct assigns: %{}, from: nil, to: nil, subject: nil, html_body: nil, text_body: nil, view: nil
  defstruct ~W[assigns from to subject html_body text_body view]a

  @doc ~S"""
  Creates (initializes) an empty email
  """
  @spec new() :: t
  def new do
    %__MODULE__{
      assigns: %{},
      to: nil,
      from: nil,
      subject: nil,
      html_body: nil,
      text_body: nil,
      view: nil,
    }
  end

  # TODO: temporary
  for field <- ~W[to subject]a do
    @spec unquote(field)(email :: t, value :: any) :: t
    def unquote(field)(email = %__MODULE__{}, value) do
      %{email | unquote(field) => value}
    end
  end

  @doc ~S"""
  Sets the *from* header of *email*
  """
  @spec from(email :: t, from :: any) :: t
  def from(email = %__MODULE__{}, from)
    when is_binary(from)
  do
    from(email, {"", from})
  end

  def from(email = %__MODULE__{}, from = {_name, _address}) do
    %{email | from: from}
  end

  @doc ~S"""
  Sets an assign for the email. These will be available when rendering the email.
  """
  @spec assign(email :: t, key :: atom, value :: any) :: t
  def assign(email = %__MODULE__{assigns: assigns}, key, value)
    when is_atom(key)
  do
    %{email | assigns: Map.put(assigns, key, value)}
  end

  @doc ~S"""
  Sets the templates for when rendering the email as HTML and plain text.
  """
  @spec put_template(email :: t, module :: module, view_suffix :: atom | String.t, template :: atom | String.t) :: t
  if Haytni.Helpers.phoenix17?() do
    def put_template(email = %__MODULE__{}, module, view_suffix, template)
      when is_atom(module)
    do
      [
        text_body: "text",
        html_body: "html",
      ]
      |> Enum.reduce(
        email,
        fn {field, format}, email ->
          full_view_suffix = view_suffix <> (format |> String.upcase())
          view_module =
            [
              module.web_module(),
              :Haytni,
              module.scope() |> to_string() |> Phoenix.Naming.camelize(),
              full_view_suffix
            ]
            |> Module.concat()
            |> Code.ensure_compiled()
            |> case do
              {:module, module} ->
                module
              _ ->
                Module.concat([module.web_module(), :Haytni, full_view_suffix])
            end

          %{email | field => Phoenix.Template.render_to_string(view_module, template |> to_string(), format, email.assigns)}
        end
      )
    end
  else
    def put_template(email = %__MODULE__{}, module, view_suffix, template)
      when is_atom(module)
    do
      view_suffix =
        view_suffix
        |> to_string()
        |> Haytni.Helpers.maybe_suffix("View")

      [
        text_body: "text",
        html_body: "html",
      ]
      |> Enum.reduce(
        email,
        fn {field, format}, email ->
          view_module =
            [
              module.web_module(),
              :Haytni,
              module.scope() |> to_string() |> Phoenix.Naming.camelize(),
              :Email,
              view_suffix,
            ]
            |> Module.concat()
            |> Code.ensure_compiled()
            |> case do
              {:module, module} ->
                module
              _ ->
                Module.concat([module.web_module(), :Haytni, :Email, view_suffix])
            end

          %{email | field => Phoenix.View.render_to_string(view_module, Enum.join([template, format], "."), email.assigns)}
        end
      )
    end

    @doc ~S"""
    Stores the view for rendering the email.
    """
    @spec put_view(email :: t, view :: module) :: t
    def put_view(email = %__MODULE__{}, view) do
      %{email | view: view}
    end

    @doc ~S"""
    Set and infer the full name of the view for email from *module* and its scope.

    Example: if `view_suffix = "Email.NewLoginNotification"` and scope associated to *module* is `:admin`
    the view module is set to `YourAppWeb.Admin.Email.NewLoginNotification` if it exists else fallback to
    `YourAppWeb.Email.NewLoginNotification`.
    """
    @spec put_view(email :: t, module :: module, view_suffix :: atom | String.t) :: t
    def put_view(email = %__MODULE__{}, module, view_suffix) do
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
    Sets the template for the subject of the email as plain text.

    Notes:

      * the view (see `put_view/2`) has to be set prior to `put_subject_template/2`
      * `put_subject_template/2` overrides any previously set subject (by `put_subject_template/2` as well as `subject/2`)
    """
    @spec put_subject_template(email :: t, template :: String.t) :: t
    def put_subject_template(email = %__MODULE__{view: view}, template)
      when not is_nil(view)
    do
      %{email | subject: Phoenix.View.render_to_string(view, template, email.assigns)}
    end

    @doc ~S"""
    Sets the template for when rendering the email as plain text.

    NOTE: the view (see `put_view/2`) has to be set prior to a call to `put_text_template/2`.
    """
    @spec put_text_template(email :: t, template :: String.t) :: t
    def put_text_template(email = %__MODULE__{view: view}, template)
      when not is_nil(view)
    do
      %{email | text_body: Phoenix.View.render_to_string(view, template, email.assigns)}
    end

    @doc ~S"""
    Same as `put_text_template/2` but for rendering the email as HTML.

    NOTE: the view (see `put_view/2`) has to be set prior to a call to `put_html_template/2`.
    """
    @spec put_html_template(email :: t, template :: String.t) :: t
    def put_html_template(email = %__MODULE__{view: view}, template)
      when not is_nil(view)
    do
      %{email | html_body: Phoenix.View.render_to_string(view, template, email.assigns)}
    end
  end
end
