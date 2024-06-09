defmodule Haytni.RecoverableEmail do
  import Haytni.Mail

  @doc ~S"""
  Email the recovery password token to *user*
  """
  @spec reset_password_email(user :: Haytni.user, reset_password_token :: String.t, module :: module, config :: Haytni.config) :: Haytni.Mail.t
  def reset_password_email(user = %_{}, reset_password_token, module, _config) do
    new()
    |> to(user.email)
    |> assign(:user, user)
    |> assign(:reset_password_token, reset_password_token)
    |> from(module.mailer().from())
    |> put_template(module, "Recoverable", "reset_password_instructions")
  end
end
