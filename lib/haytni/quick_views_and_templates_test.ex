defmodule Haytni.QuickViewsAndTemplatesTest do
  @spec view_module(module :: module, view_suffix :: atom | String.t) :: module
  defp view_module(module, view_suffix) do
    [module.web_module(), :Haytni, Phoenix.Naming.camelize(to_string(module.scope())), view_suffix]
    |> Module.concat()
    |> Code.ensure_compiled()
    |> case do
      {:module, module} ->
        module
      _ ->
        Module.concat([module.web_module(), :Haytni, view_suffix])
    end
  end

  @spec check_views_and_templates(module :: module, additionnal_attrs :: Keyword.t) :: Haytni.irrelevant | no_return
  def check_views_and_templates(module, additionnal_attrs \\ []) do
    user =
      module.schema()
      |> struct(Keyword.merge([email: "my email address"], additionnal_attrs))

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_private(:haytni, module)
      |> Plug.Conn.put_private(:phoenix_controller, Dummy)
      |> Plug.Conn.put_private(:phoenix_endpoint, module.endpoint())

    if Haytni.plugin_enabled?(module, Haytni.AuthenticablePlugin) do
      config = module.fetch_config(Haytni.AuthenticablePlugin)

      _content =
        module
        |> view_module(SessionView)
        |> Phoenix.View.render_to_string("new.html", conn: conn, config: config, module: module, changeset: Haytni.AuthenticablePlugin.session_changeset(config))
    end

    if Haytni.plugin_enabled?(module, Haytni.RegisterablePlugin) do
      config = module.fetch_config(Haytni.RegisterablePlugin)

      _content =
        module
        |> view_module(RegistrationView)
        |> Phoenix.View.render_to_string("new.html", conn: conn, config: config, module: module, changeset: Haytni.change_user(module))
    end

    if Haytni.plugin_enabled?(module, Haytni.LockablePlugin) do
      config = module.fetch_config(Haytni.LockablePlugin)

      _content =
        module
        |> view_module(UnlockView)
        |> Phoenix.View.render_to_string("new.html", conn: conn, config: config, module: module, changeset: Haytni.LockablePlugin.unlock_request_changeset(config))

      %Bamboo.Email{} = Haytni.LockableEmail.unlock_instructions_email(user, "the unlock token", module, config)
    end

    if Haytni.plugin_enabled?(module, Haytni.RecoverablePlugin) do
      config = module.fetch_config(Haytni.RecoverablePlugin)

      _content =
        module
        |> view_module(PasswordView)
        |> Phoenix.View.render_to_string("new.html", conn: conn, config: config, module: module, changeset: Haytni.RecoverablePlugin.recovering_changeset(config))

      %Bamboo.Email{} = Haytni.RecoverableEmail.reset_password_email(user, "the reset password token", module, config)
    end

    if Haytni.plugin_enabled?(module, Haytni.ConfirmablePlugin) do
      config = module.fetch_config(Haytni.ConfirmablePlugin)

      _content =
        module
        |> view_module(ConfirmationView)
        |> Phoenix.View.render_to_string("new.html", conn: conn, config: config, module: module, changeset: Haytni.ConfirmablePlugin.confirmation_request_changeset(config))

      %Bamboo.Email{} = Haytni.ConfirmableEmail.confirmation_email(user, "the confirmation token", module, config)
      %Bamboo.Email{} = Haytni.ConfirmableEmail.reconfirmation_email(user, "my new email address", "the reconfirmation token", module, config)
      %Bamboo.Email{} = Haytni.ConfirmableEmail.email_changed(user, "my old email address", module, config)
    end

    if Haytni.plugin_enabled?(module, Haytni.InvitablePlugin) do
      config = module.fetch_config(Haytni.InvitablePlugin)
      invitation = Haytni.InvitablePlugin.build_and_assoc_invitation(user)

      _content =
        module
        |> view_module(InvitationView)
        |> Phoenix.View.render_to_string("new.html", conn: conn, config: config, module: module, changeset: Haytni.InvitablePlugin.invitation_to_changeset(invitation, config))

      %Bamboo.Email{} = Haytni.InvitableEmail.invitation_email(user, invitation, module, config)
    end
  end
end
