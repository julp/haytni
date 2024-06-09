defmodule Haytni.LockableEmail do
  import Haytni.Mail

  @doc ~S"""
  Email the token to unlock *user* account
  """
  @spec unlock_instructions_email(user :: Haytni.user, unlock_token :: String.t, module :: module, config :: Haytni.config) :: Haytni.Mail.t
  def unlock_instructions_email(user = %_{}, unlock_token, module, _config) do
    new()
    |> to(user.email)
    |> assign(:user, user)
    |> assign(:unlock_token, unlock_token)
    |> from(module.mailer().from())
    |> put_template(module, "Lockable", "unlock_instructions")
  end
end
