defmodule Haytni.ConfirmableEmail do
  import Haytni.Mail
  import Bamboo.Email
  import Haytni.Gettext

  @spec common_mail_tasks(mail :: Bamboo.Email.t, user :: Haytni.user, module :: module, config :: Haytni.config) :: Bamboo.Email.t
  defp common_mail_tasks(mail, user = %_{}, module, _config) do
    mail
    |> assign(:user, user)
    |> from(module.mailer().from())
    |> put_view(Module.concat([module.web_module(), :Haytni, :Email, :ConfirmableView]))
  end

  @doc ~S"""
  The confirmation request sent by email at registration
  """
  @spec confirmation_email(user :: Haytni.user, module :: module, config :: Haytni.config) :: Bamboo.Email.t
  def confirmation_email(user = %_{}, module, config) do
    new_email()
    |> to(user.email)
    |> common_mail_tasks(user, module, config)
    |> subject(dgettext("haytni", "Please confirm your account"))
    |> put_text_template("confirmation_instructions.text")
    |> put_html_template("confirmation_instructions.html")
  end

  @doc ~S"""
  The reconfirmation request sent by email when the user change the email address of its own account
  """
  @spec reconfirmation_email(user :: Haytni.user, module :: module, config :: Haytni.config) :: Bamboo.Email.t
  def reconfirmation_email(user = %_{}, module, config) do
    new_email()
    |> to(user.unconfirmed_email)
    |> common_mail_tasks(user, module, config)
    |> subject(dgettext("haytni", "Please confirm your email address change"))
    |> put_text_template("reconfirmation_instructions.text")
    |> put_html_template("reconfirmation_instructions.html")
  end

  @doc ~S"""
  When email address is modified, send a notice of this change to the user on its previous email address
  """
  @spec email_changed(user :: Haytni.user, old_email_address :: String.t, module :: module, config :: Haytni.config) :: Bamboo.Email.t
  def email_changed(user = %_{}, old_email_address, module, config) do
    new_email()
    |> to(old_email_address)
    |> common_mail_tasks(user, module, config)
    |> assign(:config, config)
    |> assign(:old_email_address, old_email_address)
    |> subject(dgettext("haytni", "Attention: email was changed"))
    |> put_text_template("email_changed.text")
    |> put_html_template("email_changed.html")
  end
end
