defmodule Haytni.ConfirmableEmail do
  import Haytni.Mail

  @spec common_mail_tasks(mail :: Haytni.Mail.t, user :: Haytni.user, module :: module, config :: Haytni.config, template :: String.t) :: Haytni.Mail.t
  defp common_mail_tasks(mail, user = %_{}, module, _config, template) do
    mail
    |> assign(:user, user)
    |> from(module.mailer().from())
    |> put_template(module, "Confirmable", template)
  end

  @doc ~S"""
  The confirmation request sent by email at registration
  """
  @spec confirmation_email(user :: Haytni.user, confirmation_token :: String.t, module :: module, config :: Haytni.config) :: Haytni.Mail.t
  def confirmation_email(user = %_{}, confirmation_token, module, config) do
    new()
    |> to(user.email)
    |> assign(:confirmation_token, confirmation_token)
    |> common_mail_tasks(user, module, config, "confirmation_instructions")
  end

  @doc ~S"""
  The reconfirmation request sent by email when the user change the email address of its own account
  """
  @spec reconfirmation_email(user :: Haytni.user, unconfirmed_email :: String.t, confirmation_token :: String.t, module :: module, config :: Haytni.config) :: Haytni.Mail.t
  def reconfirmation_email(user = %_{}, unconfirmed_email, confirmation_token, module, config) do
    new()
    |> to(unconfirmed_email)
    |> assign(:unconfirmed_email, unconfirmed_email)
    |> assign(:confirmation_token, confirmation_token)
    |> common_mail_tasks(user, module, config, "reconfirmation_instructions")
  end

  @doc ~S"""
  When email address is modified, send a notice of this change to the user on its previous email address
  """
  @spec email_changed(user :: Haytni.user, old_email_address :: String.t, module :: module, config :: Haytni.config) :: Haytni.Mail.t
  def email_changed(user = %_{}, old_email_address, module, config) do
    new()
    |> to(old_email_address)
    |> assign(:config, config)
    |> assign(:old_email_address, old_email_address)
    |> common_mail_tasks(user, module, config, "email_changed")
  end
end
