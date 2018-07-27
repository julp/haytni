defmodule Haytni.RecoverableEmail do
  import Haytni.Mail
  import Bamboo.Email
  import Haytni.Gettext

  def reset_password_email(user = %_{}) do
    new_email()
    |> to(user.email)
    |> assign(:user, user)
    |> from(Haytni.mailer().from())
    |> subject(dgettext("haytni", "Reset password instructions"))
    |> put_view(Module.concat([Haytni.web_module(), :Haytni, :Email, :RecoverableView]))
    |> put_text_template("reset_password_instructions.text")
    |> put_html_template("reset_password_instructions.html")
  end
end
