# NOTE: default name is still ErrorView (not ErrorHTML) - see source of the private function Phoenix.Endpoint.Supervisor.render_errors/1
defmodule HaytniTestWeb.ErrorView do
  use HaytniTestWeb, :html

  # If you want to customize your error pages,
  # uncomment the embed_templates/1 call below
  # and add pages to the error directory:
  #
  #   * lib/shop_web/controllers/error_html/404.html.heex
  #   * lib/shop_web/controllers/error_html/500.html.heex
  #
  embed_templates "error_html/*"

  # The default is to render a plain text page based on
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
