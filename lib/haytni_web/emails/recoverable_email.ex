defmodule Haytni.RecoverableEmail do
  import Haytni.Mail
  import Bamboo.Email
  import Haytni.Gettext

  @doc ~S"""
  Email the recovery password token to *user*
  """
  @spec reset_password_email(user :: Haytni.user, reset_password_token :: String.t, module :: module, config :: Haytni.config) :: Haytni.email
  def reset_password_email(user = %_{}, reset_password_token, module, _config) do
    new_email()
    |> to(user.email)
    |> assign(:user, user)
    |> assign(:reset_password_token, reset_password_token)
    |> from(module.mailer().from())
    |> subject(dgettext("haytni", "Reset password instructions"))
    |> put_view(module, "Email.RecoverableView")
    |> put_text_template("reset_password_instructions.text")
    |> put_html_template("reset_password_instructions.html")
  end
end
