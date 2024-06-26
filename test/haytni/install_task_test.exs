defmodule Haytni.InstallTaskTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Haytni.TestHelpers

  @plugins [
    Haytni.AuthenticablePlugin,
    Haytni.ConfirmablePlugin,
    Haytni.LockablePlugin,
    Haytni.PasswordPolicyPlugin,
    Haytni.RecoverablePlugin,
    Haytni.RegisterablePlugin,
    Haytni.RememberablePlugin,
    Haytni.LastSeenPlugin,
    Haytni.TrackablePlugin,
    Haytni.InvitablePlugin,
    Haytni.LiveViewPlugin,
    Haytni.ClearSiteDataPlugin,
    Haytni.EncryptedEmailPlugin,
    Haytni.AnonymizationPlugin,
    Haytni.RolablePlugin,
  ]

  @spec file_list_for(plugin :: module, scope :: String.t, table :: String.t, camelized_scope :: String.t) :: [{String.t, Haytni.TestHelpers.match}]
  defp file_list_for(Haytni, scope, table, camelized_scope) do
    [
      # views
      {"lib/haytni_web/views/haytni/#{scope}/shared_view.ex", [
        "defmodule HaytniWeb.Haytni.#{camelized_scope}.SharedView do",
      ]},
      # templates
      {"lib/haytni_web/templates/haytni/#{scope}/shared/keys.html.heex", []},
      {"lib/haytni_web/templates/haytni/#{scope}/shared/message.html.heex", []},
      {"lib/haytni_web/templates/haytni/#{scope}/shared/links.html.heex", []},
      # migration
      {"priv/repo/migrations/*_haytni_#{scope}_tokens_creation.exs", [
        ~s'def change(users_table \\\\ "#{table}", _scope \\\\ "#{scope}") do',
        "defmodule Haytni.Migrations.#{camelized_scope}.TokensCreation do",
      ]},
      # test
      {"test/haytni/haytni_quick_views_and_templates_test.exs", [
        "defmodule Haytni.Haytni.#{camelized_scope}.QuickViewsAndTemplatesTest do",
      ]},
    ]
  end

  defp file_list_for(Haytni.AuthenticablePlugin, scope, table, camelized_scope) do
    [
      # views
      {"lib/haytni_web/views/haytni/#{scope}/session_view.ex", [
        "defmodule HaytniWeb.Haytni.#{camelized_scope}.SessionView do"
      ]},
      # templates
      {"lib/haytni_web/templates/haytni/#{scope}/session/new.html.heex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_session_path(",
      ]},
      # migration
      {"priv/repo/migrations/*_haytni_authenticable_#{scope}_changes.exs", [
        ~s'def change(users_table \\\\ "#{table}") do',
        "defmodule Haytni.Migrations.#{camelized_scope}.AuthenticableCreation do",
      ]},
    ]
  end

  defp file_list_for(Haytni.RegisterablePlugin, scope, _table, camelized_scope) do
    [
      # views
      {"lib/haytni_web/views/haytni/#{scope}/registration_view.ex", [
        "defmodule HaytniWeb.Haytni.#{camelized_scope}.RegistrationView do",
      ]},
      # templates
      {"lib/haytni_web/templates/haytni/#{scope}/registration/new.html.heex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_registration_path(",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/registration/edit.html.heex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_registration_path(",
      ]},
    ]
  end

  defp file_list_for(Haytni.TrackablePlugin, scope, table, camelized_scope) do
    [
      # migration
      {"priv/repo/migrations/*_haytni_trackable_#{scope}_changes.exs", [
        ~s'def change(users_table \\\\ "#{table}", scope \\\\ "#{scope}") do',
        "defmodule Haytni.Migrations.#{camelized_scope}.TrackableChanges do",
      ]},
    ]
  end

  defp file_list_for(Haytni.LastSeenPlugin, scope, table, camelized_scope) do
    [
      # migration
      {"priv/repo/migrations/*_haytni_last_seen_#{scope}_changes.exs", [
        ~s'def change(users_table \\\\ "#{table}") do',
        "defmodule Haytni.Migrations.#{camelized_scope}.LastSeenChanges do",
      ]},
    ]
  end

  defp file_list_for(Haytni.InvitablePlugin, scope, table, camelized_scope) do
    [
      # views
      {"lib/haytni_web/views/haytni/#{scope}/invitation_view.ex", [
        "defmodule HaytniWeb.Haytni.#{camelized_scope}.InvitationView do",
      ]},
      {"lib/haytni_web/views/haytni/#{scope}/email/invitable_view.ex", [
        "defmodule HaytniWeb.Haytni.#{camelized_scope}.Email.InvitableView do",
      ]},
      # templates
      {"lib/haytni_web/templates/haytni/#{scope}/invitation/new.html.heex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_invitation_path(",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/email/invitable/invitation.text.eex", []},
      {"lib/haytni_web/templates/haytni/#{scope}/email/invitable/invitation.html.heex", []},
      # migration
      {"priv/repo/migrations/*_haytni_invitable_#{scope}_creation.exs", [
        ~s'def change(users_table \\\\ "#{table}", _scope \\\\ "#{scope}") do',
        "defmodule Haytni.Migrations.#{camelized_scope}.InvitableCreation do",
      ]},
    ]
  end

  defp file_list_for(Haytni.LockablePlugin, scope, table, camelized_scope) do
    [
      # views
      {"lib/haytni_web/views/haytni/#{scope}/unlock_view.ex", [
        "defmodule HaytniWeb.Haytni.#{camelized_scope}.UnlockView do",
      ]},
      {"lib/haytni_web/views/haytni/#{scope}/email/lockable_view.ex", [
        "defmodule HaytniWeb.Haytni.#{camelized_scope}.Email.LockableView do",
      ]},
      # templates
      {"lib/haytni_web/templates/haytni/#{scope}/unlock/new.html.heex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_unlock_path(",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/email/lockable/unlock_instructions.text.eex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_unlock_url(",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/email/lockable/unlock_instructions.html.heex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_unlock_url(",
      ]},
      # migration
      {"priv/repo/migrations/*_haytni_lockable_#{scope}_changes.exs", [
        ~s'def change(users_table \\\\ "#{table}") do',
        "defmodule Haytni.Migrations.#{camelized_scope}.LockableChanges do",
      ]},
    ]
  end

  defp file_list_for(Haytni.RecoverablePlugin, scope, _table, camelized_scope) do
    [
      # views
      {"lib/haytni_web/views/haytni/#{scope}/password_view.ex", [
        "defmodule HaytniWeb.Haytni.#{camelized_scope}.PasswordView do",
      ]},
      {"lib/haytni_web/views/haytni/#{scope}/email/recoverable_view.ex", [
        "defmodule HaytniWeb.Haytni.#{camelized_scope}.Email.RecoverableView do",
      ]},
      # templates
      {"lib/haytni_web/templates/haytni/#{scope}/password/new.html.heex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_password_path(",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/password/edit.html.heex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_password_path(",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/email/recoverable/reset_password_instructions.text.eex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_password_url(",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/email/recoverable/reset_password_instructions.html.heex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_password_url(",
      ]},
    ]
  end

  defp file_list_for(Haytni.ConfirmablePlugin, scope, table, camelized_scope) do
    [
      # views
      {"lib/haytni_web/views/haytni/#{scope}/confirmation_view.ex", [
        "defmodule HaytniWeb.Haytni.#{camelized_scope}.ConfirmationView do",
      ]},
      {"lib/haytni_web/views/haytni/#{scope}/email/confirmable_view.ex", [
        "defmodule HaytniWeb.Haytni.#{camelized_scope}.Email.ConfirmableView do",
      ]},
      # templates
      {"lib/haytni_web/templates/haytni/#{scope}/confirmation/new.html.heex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_confirmation_path(",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/email/confirmable/email_changed.text.eex", []},
      {"lib/haytni_web/templates/haytni/#{scope}/email/confirmable/email_changed.html.heex", []},
      {"lib/haytni_web/templates/haytni/#{scope}/email/confirmable/confirmation_instructions.text.eex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_confirmation_url(",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/email/confirmable/confirmation_instructions.html.heex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_confirmation_url(",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/email/confirmable/reconfirmation_instructions.text.eex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_reconfirmation_url(",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/email/confirmable/reconfirmation_instructions.html.heex", [
        "HaytniWeb.Router.Helpers.haytni_#{scope}_reconfirmation_url(",
      ]},
      # migration
      {"priv/repo/migrations/*_haytni_confirmable_#{scope}_changes.exs", [
        ~s'def change(users_table \\\\ "#{table}") do',
        "defmodule Haytni.Migrations.#{camelized_scope}.ConfirmableChanges do",
      ]},
    ]
  end

  defp file_list_for(Haytni.EncryptedEmailPlugin, scope, table, camelized_scope) do
    [
      # migration
      {"priv/repo/migrations/*_haytni_encrypted_email_#{scope}_changes.exs", [
        ~s'def change(users_table \\\\ "#{table}") do',
        "defmodule Haytni.Migrations.#{camelized_scope}.EncryptedEmailChanges do",
      ]},
    ]
  end

  defp file_list_for(Haytni.RolablePlugin, scope, table, camelized_scope) do
    [
      # views
      {"lib/haytni_web/views/haytni/#{scope}/role_view.ex", [
        "defmodule HaytniWeb.Haytni.#{camelized_scope}.RoleView do",
      ]},
      # templates
      {"lib/haytni_web/templates/haytni/#{scope}/role/_form.html.heex", [
        "<%=",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/role/new.html.heex", [
        "<%=",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/role/edit.html.heex", [
        "<%=",
      ]},
      {"lib/haytni_web/templates/haytni/#{scope}/role/index.html.heex", [
        "<%=",
      ]},
      # migration
      {"priv/repo/migrations/*_haytni_rolable_#{scope}_changes.exs", [
        ~s'def change(users_table \\\\ "#{table}", _scope \\\\ "#{scope}") do',
        "defmodule Haytni.Migrations.#{camelized_scope}.RolableChanges do",
      ]},
    ]
  end

  defp file_list_for(_plugin, _scope, _table, _camelized_scope), do: []

  defp is_wildcard?(file) do
    String.contains?(file, "*")
  end

  defp to_assertion(true, {file, match}) do
    file = if is_wildcard?(file) do
      assert [file] = Path.wildcard(file)
      file
    else
      file
    end
    apply(Haytni.TestHelpers, :assert_file, [file, match])
  end

  defp to_assertion(false, {file, _}) do
    if is_wildcard?(file) do
      assert [] == Path.wildcard(file)
    else
      refute_file file
    end
  end

  @spec check_files(plugins :: [module], scope :: String.t, table :: String.t) :: :ok | no_return
  defp check_files(plugins, scope, table)
    when is_binary(scope) and is_binary(table)
  do
    camelized_scope =
      scope
      |> to_string()
      |> Phoenix.Naming.camelize()

    in_tmp_project(
        "haytni",
        fn ->
          capture_io(
            fn ->
              ["" | plugins]
              |> Enum.intersperse("--plugin")
              |> Kernel.++(["--scope", scope, "--table", table])
              |> Mix.Tasks.Haytni.Install.run()
            end
          )

          if Haytni.AuthenticablePlugin in plugins do
            assert_file "lib/haytni/haytni.ex", fn content ->
              assert Haytni.AuthenticablePlugin in plugins == String.contains?(content, "stack Haytni.AuthenticablePlugin")
              assert Haytni.RegisterablePlugin in plugins == String.contains?(content, "stack Haytni.RegisterablePlugin")
              assert Haytni.RememberablePlugin in plugins == String.contains?(content, "stack Haytni.RememberablePlugin")
              assert Haytni.ConfirmablePlugin in plugins == String.contains?(content, "stack Haytni.ConfirmablePlugin")
              assert Haytni.LockablePlugin in plugins == String.contains?(content, "stack Haytni.LockablePlugin")
              assert Haytni.RecoverablePlugin in plugins == String.contains?(content, "stack Haytni.RecoverablePlugin")
              assert Haytni.TrackablePlugin in plugins == String.contains?(content, "stack Haytni.TrackablePlugin")
              assert Haytni.PasswordPolicyPlugin in plugins == String.contains?(content, "stack Haytni.PasswordPolicyPlugin")
              assert Haytni.InvitablePlugin in plugins == String.contains?(content, "stack Haytni.InvitablePlugin")
              assert Haytni.LastSeenPlugin in plugins == String.contains?(content, "stack Haytni.LastSeenPlugin")
              assert Haytni.EncryptedEmailPlugin in plugins == String.contains?(content, "stack Haytni.EncryptedEmailPlugin")
              assert Haytni.AnonymizationPlugin in plugins == String.contains?(content, "stack Haytni.AnonymizationPlugin")
              assert Haytni.ClearSiteDataPlugin in plugins == String.contains?(content, "stack Haytni.ClearSiteDataPlugin")
            end
          end

          Enum.each(
            @plugins ++ [Haytni],
            fn plugin ->
              Enum.each(
                file_list_for(plugin, scope, table, camelized_scope),
                &(to_assertion(Haytni == plugin or plugin in plugins, &1))
              )
            end
          )
        end
      )
  end

  describe "mix haytni.install" do
    setup do
      Mix.Task.clear()
      :ok
    end

    test "checks all necessary files are correctly generated for --plugin Haytni.AuthenticablePlugin --scope user --table users" do
      check_files([Haytni.AuthenticablePlugin], "user", "users")
    end

    for plugin <- @plugins do
      scope = random_string(8)
      table = random_string(8)
      test "checks all necessary files are correctly generated for --plugin #{plugin} --scope #{scope} --table #{table}" do
        check_files([unquote(plugin)], unquote(scope), unquote(table))
      end
    end

    test "checks all necessary files are correctly generated for all plugins with --scope abc --table def" do
      check_files(@plugins, "abc", "def")
    end
  end
end
