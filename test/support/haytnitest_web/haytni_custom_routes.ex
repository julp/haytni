defmodule HaytniTestWeb.HaytniCustomRoutes do
  use Haytni, otp_app: :haytni_test

  stack Haytni.SessionPlugin
  stack Haytni.AuthenticablePlugin, hashing_method: ExPassword.Bcrypt, hashing_options: %{cost: 4}
  stack Haytni.RegisterablePlugin
  #stack Haytni.RememberablePlugin
  stack Haytni.ConfirmablePlugin
  stack Haytni.LockablePlugin
  stack Haytni.RecoverablePlugin
  #stack Haytni.LastSeenPlugin
  #stack Haytni.TrackablePlugin
  #stack Haytni.PasswordPolicyPlugin
end
