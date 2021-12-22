defmodule HaytniTestWeb.HaytniAdmin do
  use Haytni, otp_app: :haytni_test

  stack Haytni.AuthenticablePlugin, hashing_method: ExPassword.Bcrypt, hashing_options: %{cost: 4}
  stack Haytni.LockablePlugin
  stack Haytni.TrackablePlugin
end
