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
  stack Haytni.LiveViewPlugin

  @impl Haytni.Callbacks
  def user_query(query) do
    import Ecto.Query

    if has_named_binding?(query, :user) do
      from(
        [{:user, u}] in query,
        #[token: t, user: u] in exclude(query, :select),
        #[{:user, u}] in exclude(query, :select),
        #select: [l, u],
        #select: [user: :language],
        left_join: l in assoc(u, :language),
        preload: [language: l]
        #preload: [user: {u, language: l}] # <=
        #preload: [user: {l, :language}]
        #preload: [{:user, {u, :language}}]
      )
    else
      from(
        u in query,
        left_join: l in assoc(u, :language),
        #select: [u, l],
        preload: [language: l]
      )
    end
  end
end
