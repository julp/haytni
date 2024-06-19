defmodule Haytni.Mail do
  @moduledoc ~S"""
  An abstraction layer to build emails before actually sending them
  """

  @type name :: String.t
  @type address :: String.t
  # Haytni.user (struct) could be supported if user defimp Swoosh.Email.Recipient/Bamboo.Formatter
  @type recipient :: address | {name, address}
  @type recipients :: [recipient]

  @type t :: %__MODULE__{
    assigns: %{atom => any},
    to: recipients,
    cc: recipients,
    bcc: recipients,
    from: recipient, # there is one Sender but could have multiple From, so it should be `recipients`?
    views: [module],
    subject: Haytni.nilable(String.t),
    html_body: Haytni.nilable(String.t),
    text_body: Haytni.nilable(String.t),
    headers: %{String.t => String.t},
  }

  @recipients_header ~W[to cc bcc]a
  @other_headers_with_a_field ~W[subject from]a

  # TODO: layout ?
  #defstruct assigns: %{}, from: nil, to: nil, subject: nil, html_body: nil, text_body: nil, views: []
  defstruct ~W[assigns headers html_body text_body views]a ++ @recipients_header ++ @other_headers_with_a_field

  @doc ~S"""
  Creates (initializes) an empty email
  """
  @spec new() :: t
  def new do
    %__MODULE__{
      assigns: %{},
      to: [],
      cc: [],
      bcc: [],
      from: nil,
      subject: nil,
      html_body: nil,
      text_body: nil,
      views: [],
      headers: %{},
    }
  end

  @doc ~S"""
  Sets the *subject* header of *email*
  """
  @spec subject(email :: t, subject :: String.t) :: t
  def subject(email = %__MODULE__{}, subject)
    when is_binary(subject)
  do
    %{email | subject: subject}
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

  def to(email = %__MODULE__{}, recipients) do
    put_to(email, List.wrap(recipients))
  end

  for field <- @recipients_header do
    @spec unquote(:"put_#{field}")(email :: t, recipients :: recipients) :: t
    def unquote(:"put_#{field}")(email = %__MODULE__{}, recipients)
      when is_list(recipients)
    do
      %{email | unquote(field) => recipients}
    end

    @spec unquote(:"add_#{field}")(email :: t, recipient :: recipient) :: t
    def unquote(:"add_#{field}")(email = %__MODULE__{unquote(field) => recipients}, recipient) do
      %{email | unquote(field) => [recipient | recipients]}
    end
  end

  for name <- @other_headers_with_a_field do
    defp do_put_header(_email, name = unquote(to_string(name)), _value) do
      raise "Use #{name}/3 to set the #{name} header instead of put_header/3"
    end
  end

  for name <- @recipients_header do
    defp do_put_header(_email, name = unquote(to_string(name)), _value) do
      raise "Use put_#{name}/2 or add_#{name}/2 instead of put_header/3"
    end
  end

  defp do_put_header(email, name, value) do
    %{email | headers: Map.put(email.headers, name, value)}
  end

  @doc ~S"""
  Adds a new header to *email*

  Note: names are unique, *value* will override any previous one defined for *name*
  """
  @spec put_header(email :: t, name :: String.t, value :: String.t) :: t
  def put_header(email = %__MODULE__{}, name, value)
    when is_binary(name) and is_binary(value)
  do
    do_put_header(email, String.downcase(name), value)
  end

  @doc ~S"""
  Directly sets the HTML body of the email (without involving a view)
  """
  @spec html_body(email :: t, body :: String.t) :: t
  def html_body(email, body) do
    %{email | html_body: body}
  end

  @doc ~S"""
  Directly sets the text body of the email (without involving a view)
  """
  @spec text_body(email :: t, body :: String.t) :: t
  def text_body(email, body) do
    %{email | text_body: body}
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
  Stores the view for rendering the email.
  """
  @spec put_view(email :: t, view :: module) :: t
  def put_view(email = %__MODULE__{}, view) do
    %{email | views: [view]}
  end

  @doc ~S"""
  Set and infer the full name of the view for email from *module* and its scope.

  Example: if `view_suffix = "NewLoginNotification"` and scope associated to *module* is `:admin` the view module is set to `YourAppWeb.Haytni.Admin.Email.NewLoginNotificationView` (`YourAppWeb.Haytni.Admin.NewLoginNotificationEmails` for Phoenix 1.7) if it exists else fallback to `YourAppWeb.Haytni.Email.NewLoginNotificationView` (`YourAppWeb.Haytni.NewLoginNotificationEmails` for Phoenix 1.7).

  This view module is used to set:

    * the subject is not yet defined (by a previous `subject/2`) by calling (if it exists) its *template*_subject/1 function
    * the HTML body
    * the (plain) text body

  With Phoenix >= 1.7, the first of these two (scoped > global) "views" to implement the function is used. If, for example, you don't want to set a text version, implement it to return `nil` or an empty string. The function used to set the HTML body is *template*_html/1 and *template*_text/1 for the (plain) text body. Illustation (assuming template is "foo"):

  ```elixir
  # Phoenix >= 1.7 only
  defmodule YourAppWeb.Haytni.NewLoginNotificationEmails do
    use YourAppWeb, :html

    def foo_text(_assigns) do
      nil
    end

    # your html in the file new_login_notification_html/foo.html.heex
    embed_templates "new_login_notification_html/*", suffix: "_html"

    # which is the same as writing it here directly:
  #   def foo_html(assigns) do
  #     ~H'''
  #     your html
  #     '''
  #   end
  end
  ```

  Note: this function is intended to be used by plugin.
  """
  @spec put_view(email :: t, module :: module, view_suffix :: atom | String.t) :: t
  if Haytni.Helpers.phoenix17?() do
    def put_view(email = %__MODULE__{}, module, view_suffix) do
      view_suffix =
        view_suffix
        |> to_string()
        |> Haytni.Helpers.maybe_suffix("Emails")

      global_view_module = Module.concat([module.web_module(), :Haytni, view_suffix])

      view_modules =
        [
          module.web_module(),
          :Haytni,
          module.scope() |> to_string() |> Phoenix.Naming.camelize(),
          view_suffix,
        ]
        |> Module.concat()
        |> Code.ensure_compiled()
        |> case do
          {:module, scoped_view_module} ->
            [scoped_view_module, global_view_module]
          _ ->
            [global_view_module]
        end

      %{email | views: view_modules}
    end
  else
    def put_view(email = %__MODULE__{}, module, view_suffix) do
      view_suffix =
        view_suffix
        |> to_string()
        |> Haytni.Helpers.maybe_suffix("View")

      global_view_module = Module.concat([module.web_module(), :Haytni, :Email, view_suffix])

      view_modules =
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
          {:module, scoped_view_module} ->
            [scoped_view_module, global_view_module]
          _ ->
            [global_view_module]
        end

      %{email | views: view_modules}
    end
  end

  defp subject_from_views(email = %__MODULE__{subject: nil}, {:ok, function_name})
    when is_atom(function_name)
  do
    Enum.reduce_while(
      email.views,
      email,
      fn view_module, email_as_acc ->
        :erlang.module_loaded(view_module) or :code.ensure_loaded(view_module)
        if function_exported?(view_module, function_name, 1) do
          {:halt, subject(email_as_acc, apply(view_module, function_name, [email_as_acc.assigns]))}
        else
          {:cont, email_as_acc}
        end
      end
    )
  end

  defp subject_from_views(email = %__MODULE__{}, _function_name) do
    # NOP:
    # - subject was already set (don't override it)
    # - the function :"#{template}_subject" doesn't exist
    email
  end

  @doc """
  Same as/a shortcut to:

  ```elixir
  email
  |> #{__MODULE__}.put_view(module, view_suffix)
  |> #{__MODULE__}.put_template(module, template)
  ```
  """
  def put_template(email = %__MODULE__{}, module, view_suffix, template)
    when is_binary(view_suffix) and is_binary(template)
  do
    email
    |> put_view(module, view_suffix)
    |> put_template(module, template)
  end

  @spec string_to_existing_atom(name :: String.t) :: {:ok, atom} | :error
  defp string_to_existing_atom(name) do
    try do
      {:ok, String.to_existing_atom(name)}
    rescue
      ArgumentError -> :error
    end
  end

  @doc ~S"""
  Sets the templates for when rendering the email as HTML and plain text.
  """
  @spec put_template(email :: t, module :: module, template :: atom | String.t) :: t
  def put_template(email = %__MODULE__{views: [_head | _tail]}, module, template)
    when is_atom(module)
  do
    email
    |> bodies_from_views(template)
    |> subject_from_views(string_to_existing_atom("#{template}_subject"))
  end

  @spec render_to_string(view_module :: module, template :: String.t, format :: String.t, assigns :: %{atom => any}) :: String.t
  if Haytni.Helpers.phoenix17?() do
    # Phoenix 1.7
    defp render_to_string(view_module, template, format, assigns) do
      Phoenix.Template.render_to_string(view_module, Enum.join([template, format], "_"), format, assigns)
    end

    # use the first view in email.views that defines the function <template>_html/1 to set html_body
    defp html_body_from_views(email, template) do
      Enum.reduce_while(
        email.views,
        email,
        fn view_module, email_as_acc ->
          :erlang.module_loaded(view_module) or :code.ensure_loaded(view_module)
          # render("<template>.<format>", assigns) vs <template>_<format>(assigns) # "_<format>" is the :suffix option on embed_templates/2
          if function_exported?(view_module, String.to_existing_atom("#{template}_html"), 1) do
            {:halt, put_html_template(email_as_acc, view_module, template)}
          else
            {:cont, email_as_acc}
          end
        end
      )
    end

    # use the first view in email.views that defines the function <template>_text/1 to set text_body
    defp text_body_from_views(email, template) do
      Enum.reduce_while(
        email.views,
        email,
        fn view_module, email_as_acc ->
          :erlang.module_loaded(view_module) or :code.ensure_loaded(view_module)
          if function_exported?(view_module, String.to_existing_atom("#{template}_text"), 1) do
            {:halt, put_text_template(email_as_acc, view_module, template)}
          else
            {:cont, email_as_acc}
          end
        end
      )
    end

    defp bodies_from_views(email, template) do
      email
      |> html_body_from_views(template)
      |> text_body_from_views(template)
    end
  else
    # Phoenix 1.6
    defp render_to_string(view_module, template, format, assigns) do
      Phoenix.View.render_to_string(view_module, Enum.join([template, format], "."), assigns)
    end

    # with old views, defined as `def render("<template>.<format>", assigns)` we can't check its existence so we just use the first view (head) of email.views
    defp bodies_from_views(email = %__MODULE__{views: [view_module | _tail]}, template) do
      email
      |> put_text_template(view_module, template)
      |> put_html_template(view_module, template)
    end
  end

  @doc ~S"""
  Sets the template for when rendering the email as plain text.
  """
  @spec put_text_template(email :: t, view_module :: module, template :: String.t) :: t
  def put_text_template(email = %__MODULE__{}, view_module, template)
    when is_atom(view_module)
  do
    %{email | text_body: render_to_string(view_module, template, "text", email.assigns)}
  end

  @doc ~S"""
  Same as `put_text_template/3` but for rendering the email as HTML.
  """
  @spec put_html_template(email :: t, view_module :: module, template :: String.t) :: t
  def put_html_template(email = %__MODULE__{}, view_module, template)
    when is_atom(view_module)
  do
    %{email | html_body: render_to_string(view_module, template, "html", email.assigns)}
  end
end
