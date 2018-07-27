defmodule Haytni.LockableEmail do
  import Haytni.Mail
  import Bamboo.Email
  import Haytni.Gettext

  def unlock_instructions_email(user = %_{}) do
    new_email()
    |> to(user.email)
    |> assign(:user, user)
    |> from(Haytni.mailer().from())
    |> subject(dgettext("haytni", "Unlock instructions"))
    |> put_view(Module.concat([Haytni.web_module(), :Haytni, :Email, :LockableView]))
    |> put_text_template("unlock_instructions.text")
    |> put_html_template("unlock_instructions.html")
  end
end
