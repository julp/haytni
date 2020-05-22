defmodule HaytniTestWeb.HaytniAdmin do
  use Haytni, otp_app: :haytni_test

  stack Haytni.AuthenticablePlugin
  stack Haytni.LockablePlugin
  stack Haytni.TrackablePlugin
end
