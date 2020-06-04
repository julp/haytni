defmodule Haytni.RecoverableEmail do
  import Haytni.Mail
  import Bamboo.Email
  import Haytni.Gettext

  @doc ~S"""
  Email the recovery password token to *user*
  """
  @spec reset_password_email(user :: Haytni.user, module :: module, config :: Haytni.config) :: Bamboo.Email.t
  def reset_password_email(user = %_{}, module, _config) do
    new_email()
    |> to(user.email)
    |> assign(:user, user)
    |> from(module.mailer().from())
    |> subject(dgettext("haytni", "Reset password instructions"))
    |> put_view(module, "Email.RecoverableView")
    |> put_text_template("reset_password_instructions.text")
    |> put_html_template("reset_password_instructions.html")
  end
end
