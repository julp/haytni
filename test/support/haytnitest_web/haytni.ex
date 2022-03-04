defmodule HaytniTestWeb.Haytni do
  use Haytni, otp_app: :haytni_test

  stack Haytni.AuthenticablePlugin, hashing_method: ExPassword.Bcrypt, hashing_options: %{cost: 4}
  stack Haytni.RegisterablePlugin #, email_index_name: :users_email_index
  stack Haytni.RememberablePlugin
  stack Haytni.ConfirmablePlugin
  stack Haytni.LockablePlugin
  stack Haytni.RecoverablePlugin
  stack Haytni.TrackablePlugin
  stack Haytni.PasswordPolicyPlugin
  stack Haytni.InvitablePlugin, invitation_required: false
  stack Haytni.LiveViewPlugin
end
