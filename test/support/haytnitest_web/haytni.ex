defmodule HaytniTestWeb.Haytni do
  use Haytni, otp_app: :haytni_test

  stack Haytni.AuthenticablePlugin
  stack Haytni.RegisterablePlugin
  stack Haytni.RememberablePlugin
  stack Haytni.ConfirmablePlugin
  stack Haytni.LockablePlugin
  stack Haytni.RecoverablePlugin
  stack Haytni.TrackablePlugin
  stack Haytni.PasswordPolicyPlugin
  stack Haytni.InvitablePlugin, invitation_required: false
end
