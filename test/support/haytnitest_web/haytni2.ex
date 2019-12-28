defmodule HaytniTestWeb.Haytni2 do
  use Haytni, otp_app: :haytni_test

  stack Haytni.AuthenticablePlugin
  stack Haytni.TrackablePlugin
end
