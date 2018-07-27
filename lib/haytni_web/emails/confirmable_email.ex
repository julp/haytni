defmodule Haytni.ConfirmableEmail do
  import Haytni.Mail
  import Bamboo.Email
  import Haytni.Gettext

  defp common_mail_tasks(mail, user = %_{}) do
    mail
    |> assign(:user, user)
    |> from(Haytni.mailer().from())
    |> put_view(Module.concat([Haytni.web_module(), :Haytni, :Email, :ConfirmableView]))
  end

  @doc ~S"""
  The confirmation request sent by email at registration
  """
  def confirmation_email(user = %_{}) do
    new_email()
    |> to(user.email)
    |> common_mail_tasks(user)
    |> subject(dgettext("haytni", "Please confirm your account"))
    |> put_text_template("confirmation_instructions.text")
    |> put_html_template("confirmation_instructions.html")
  end

  @doc ~S"""
  The reconfirmation request sent by email when the user change the email address of its own account
  """
  def reconfirmation_email(user = %_{}) do
    new_email()
    |> common_mail_tasks(user)
    |> to(user.unconfirmed_email)
    |> from(Haytni.mailer().from())
    |> subject(dgettext("haytni", "Please confirm your email address change"))
    |> put_text_template("reconfirmation_instructions.text")
    |> put_html_template("reconfirmation_instructions.html")
  end

  @doc ~S"""
  When email address is modified, send a notice of this change to the user on its previous email address
  """
  def email_changed(user = %_{}, old_email_address) do
    new_email()
    |> to(old_email_address)
    |> common_mail_tasks(user)
    |> from(Haytni.mailer().from())
    |> assign(:old_email_address, old_email_address)
    |> subject(dgettext("haytni", "Attention: email was changed"))
    |> put_text_template("email_changed.text")
    |> put_html_template("email_changed.html")
  end
end
