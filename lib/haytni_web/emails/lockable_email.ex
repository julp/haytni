defmodule Haytni.LockableEmail do
  import Haytni.Mail
  import Bamboo.Email
  import Haytni.Gettext

  @doc ~S"""
  Email the token to unlock *user* account
  """
  @spec unlock_instructions_email(user :: Haytni.user, module :: module, config :: Haytni.config) :: Bamboo.Email.t
  def unlock_instructions_email(user = %_{}, module, _config) do
    new_email()
    |> to(user.email)
    |> assign(:user, user)
    |> from(module.mailer().from())
    |> subject(dgettext("haytni", "Unlock instructions"))
    |> put_view(Module.concat([module.web_module(), :Haytni, :Email, :LockableView]))
    |> put_text_template("unlock_instructions.text")
    |> put_html_template("unlock_instructions.html")
  end
end
