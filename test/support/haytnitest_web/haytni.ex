defmodule HaytniTestWeb.Haytni do
  use Haytni, otp_app: :haytni_test

  stack Haytni.AuthenticablePlugin, hashing_method: ExPassword.Bcrypt, hashing_options: %{cost: 4}
  stack Haytni.RegisterablePlugin #, email_index_name: :users_email_index
  stack Haytni.RememberablePlugin
  stack Haytni.ConfirmablePlugin
  stack Haytni.LockablePlugin
  stack Haytni.RecoverablePlugin
  stack Haytni.LastSeenPlugin
  stack Haytni.TrackablePlugin
  stack Haytni.PasswordPolicyPlugin
  stack Haytni.InvitablePlugin, invitation_required: false
  stack Haytni.LiveViewPlugin
  stack Haytni.EncryptedEmailPlugin
  stack Haytni.AnonymizationPlugin

  @impl Haytni.Callbacks
  def user_query(query) do
    import Ecto.Query

    from(
      u in query,
      #[{:user, u}] in query,
      left_join: l in assoc(u, :language),
      preload: [language: l]
    )
  end
end
