defmodule Haytni.InvitableEmail do
  import Haytni.Mail

  @doc ~S"""
  Email an invitation

  In the *invitation* templates, *user* is the sender of the invitation, you have full access to it, so you can use any field from its schema so you can
  refer to it by its surname if you like.
  """
  @spec invitation_email(user :: Haytni.user, invitation :: Haytni.InvitablePlugin.invitation, module :: module, config :: Haytni.config) :: Haytni.Mail.t
  def invitation_email(user = %_{}, invitation, module, config) do
    new()
    |> to(invitation.sent_to)
    |> assign(:user, user)
    |> assign(:config, config)
    |> assign(:invitation, invitation)
    |> from(module.mailer().from())
    |> put_template(module, "Invitable", "invitation")
  end
end
