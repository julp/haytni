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
    Haytni.TrackablePlugin,
  ]

  @spec file_list_for(plugin :: module, scope :: atom, table :: String.t, camelized_scope :: String.t) :: [{String.t, (String.t -> boolean | no_return) | nil}]
  defp file_list_for(Haytni.AuthenticablePlugin, scope, table, camelized_scope) do
    [
      # stack
      {"lib/haytni/haytni.ex", fn _content ->
#         assert Haytni.AuthenticablePlugin in plugins == String.contains?(content, "stack Haytni.AuthenticablePlugin")
#         assert Haytni.RegisterablePlugin in plugins == String.contains?(content, "stack Haytni.RegisterablePlugin")
#         assert Haytni.RememberablePlugin in plugins == String.contains?(content, "stack Haytni.RememberablePlugin")
#         assert Haytni.ConfirmablePlugin in plugins == String.contains?(content, "stack Haytni.ConfirmablePlugin")
#         assert Haytni.LockablePlugin in plugins == String.contains?(content, "stack Haytni.LockablePlugin")
#         assert Haytni.RecoverablePlugin in plugins == String.contains?(content, "stack Haytni.RecoverablePlugin")
#         assert Haytni.TrackablePlugin in plugins == String.contains?(content, "stack Haytni.TrackablePlugin")
#         assert Haytni.PasswordPolicyPlugin in plugins == String.contains?(content, "stack Haytni.PasswordPolicyPlugin")
        true
      end},
      # views
      {"lib/haytni_web/views/haytni/#{scope}/session_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.SessionView do")
      end},
      # templates
      {"lib/haytni_web/templates/haytni/#{scope}/session/new.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_session_path(")
      end},
      # shared templates
      {"lib/haytni_web/templates/haytni/#{scope}/shared/keys.html.eex", nil},
      {"lib/haytni_web/templates/haytni/#{scope}/shared/message.html.eex", nil},
      {"lib/haytni_web/templates/haytni/#{scope}/shared/links.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_session_path(")
      end},
      {"lib/haytni_web/views/haytni/#{scope}/shared_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.SharedView do")
      end},
      # migration
      {"priv/repo/migrations/*_haytni_authenticable_#{scope}_changes.ex", fn content ->
        assert String.contains?(content, ~s'def change(table \\\\ "#{table}") do')
        assert String.contains?(content, "defmodule Haytni.Migrations.#{camelized_scope}.AuthenticableCreation do")
      end},
    ]
  end

  defp file_list_for(Haytni.RegisterablePlugin, scope, _table, camelized_scope) do
    [
      # views
      {"lib/haytni_web/views/haytni/#{scope}/registration_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.RegistrationView do")
      end},
      # templates
      {"lib/haytni_web/templates/haytni/#{scope}/registration/new.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_registration_path(")
      end},
      {"lib/haytni_web/templates/haytni/#{scope}/registration/edit.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_registration_path(")
      end},
    ]
  end

  defp file_list_for(Haytni.TrackablePlugin, scope, table, camelized_scope) do
    [
      # migration
      {"priv/repo/migrations/*_haytni_trackable_#{scope}_changes.ex", fn content ->
        assert String.contains?(content, ~s'def change(table \\\\ "#{table}", scope \\\\ "#{scope}") do')
        assert String.contains?(content, "defmodule Haytni.Migrations.#{camelized_scope}.TrackableChanges do")
      end},
    ]
  end
  
  defp file_list_for(Haytni.RememberablePlugin, scope, table, camelized_scope) do
    [
      # migration
      {"priv/repo/migrations/*_haytni_rememberable_#{scope}_changes.ex", fn content ->
        assert String.contains?(content, ~s'def change(table \\\\ "#{table}") do')
        assert String.contains?(content, "defmodule Haytni.Migrations.#{camelized_scope}.RememberableChanges do")
      end},
    ]
  end

  defp file_list_for(Haytni.LockablePlugin, scope, table, camelized_scope) do
    [
      # views
      {"lib/haytni_web/views/haytni/#{scope}/unlock_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.UnlockView do")
      end},
      {"lib/haytni_web/views/haytni/#{scope}/email/lockable_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.Email.LockableView do")
      end},
      # templates
      {"lib/haytni_web/templates/haytni/#{scope}/unlock/new.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_unlock_path(")
      end},
      {"lib/haytni_web/templates/haytni/#{scope}/email/lockable/unlock_instructions.text.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_unlock_url(")
      end},
      {"lib/haytni_web/templates/haytni/#{scope}/email/lockable/unlock_instructions.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_unlock_url(")
      end},
      # migration
      {"priv/repo/migrations/*_haytni_lockable_#{scope}_changes.ex", fn content ->
        assert String.contains?(content, ~s'def change(table \\\\ "#{table}") do')
        assert String.contains?(content, "defmodule Haytni.Migrations.#{camelized_scope}.LockableChanges do")
      end},
    ]
  end

  defp file_list_for(Haytni.RecoverablePlugin, scope, table, camelized_scope) do
    [
      # views
      {"lib/haytni_web/views/haytni/#{scope}/password_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.PasswordView do")
      end},
      {"lib/haytni_web/views/haytni/#{scope}/email/recoverable_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.Email.RecoverableView do")
      end},
      # templates
      {"lib/haytni_web/templates/haytni/#{scope}/password/new.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_password_path(")
      end},
      {"lib/haytni_web/templates/haytni/#{scope}/password/edit.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_password_path(")
      end},
      {"lib/haytni_web/templates/haytni/#{scope}/email/recoverable/reset_password_instructions.text.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_password_url(")
      end},
      {"lib/haytni_web/templates/haytni/#{scope}/email/recoverable/reset_password_instructions.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_password_url(")
      end},
      # migration
      {"priv/repo/migrations/*_haytni_recoverable_#{scope}_changes.ex", fn content ->
        assert String.contains?(content, ~s'def change(table \\\\ "#{table}") do')
        assert String.contains?(content, "defmodule Haytni.Migrations.#{camelized_scope}.RecoverableChanges do")
      end},
    ]
  end

  defp file_list_for(Haytni.ConfirmablePlugin, scope, table, camelized_scope) do
    [
      # views
      {"lib/haytni_web/views/haytni/#{scope}/confirmation_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.ConfirmationView do")
      end},
      {"lib/haytni_web/views/haytni/#{scope}/email/confirmable_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.Email.ConfirmableView do")
      end},
      # templates
      {"lib/haytni_web/templates/haytni/#{scope}/confirmation/new.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_confirmation_path(")
      end},
      {"lib/haytni_web/templates/haytni/#{scope}/email/confirmable/email_changed.text.eex", nil},
      {"lib/haytni_web/templates/haytni/#{scope}/email/confirmable/email_changed.html.eex", nil},
      {"lib/haytni_web/templates/haytni/#{scope}/email/confirmable/confirmation_instructions.text.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_confirmation_url(")
      end},
      {"lib/haytni_web/templates/haytni/#{scope}/email/confirmable/confirmation_instructions.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_confirmation_url(")
      end},
      {"lib/haytni_web/templates/haytni/#{scope}/email/confirmable/reconfirmation_instructions.text.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_confirmation_url(")
      end},
      {"lib/haytni_web/templates/haytni/#{scope}/email/confirmable/reconfirmation_instructions.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_confirmation_url(")
      end},
      # migration
      {"priv/repo/migrations/*_haytni_confirmable_#{scope}_changes.ex", [
        ~s'def change(table \\\\ "#{table}") do',
        "defmodule Haytni.Migrations.#{camelized_scope}.ConfirmableChanges do",
      ]},
    ]
  end

  defp file_list_for(_plugin, _scope, _table, _camelized_scope), do: []

  defp is_wildcard?(file) do
    String.contains?(file, "*")
  end

  defp to_assertion(true, {file, fun}) do
    file = if is_wildcard?(file) do
      assert [file] = Path.wildcard(file)
      file
    else
      file
    end
    args = if fun do
      [file, fun]
    else
      [file]
    end
    apply(Haytni.TestHelpers, :assert_file, args)
  end

  defp to_assertion(false, {file, _}) do
    if is_wildcard?(file) do
      assert [] == Path.wildcard(file)
    else
      refute_file file
    end
  end

  defp check_files(plugins, scope, table) do
    camelized_scope = scope
    |> to_string()
    |> Phoenix.Naming.camelize()
    _ = """
    if Haytni.AuthenticablePlugin in plugins do
      # stack
      assert_file "lib/haytni/haytni.ex", fn content ->
        assert Haytni.AuthenticablePlugin in plugins == String.contains?(content, "stack Haytni.AuthenticablePlugin")
        assert Haytni.RegisterablePlugin in plugins == String.contains?(content, "stack Haytni.RegisterablePlugin")
        assert Haytni.RememberablePlugin in plugins == String.contains?(content, "stack Haytni.RememberablePlugin")
        assert Haytni.ConfirmablePlugin in plugins == String.contains?(content, "stack Haytni.ConfirmablePlugin")
        assert Haytni.LockablePlugin in plugins == String.contains?(content, "stack Haytni.LockablePlugin")
        assert Haytni.RecoverablePlugin in plugins == String.contains?(content, "stack Haytni.RecoverablePlugin")
        assert Haytni.TrackablePlugin in plugins == String.contains?(content, "stack Haytni.TrackablePlugin")
        assert Haytni.PasswordPolicyPlugin in plugins == String.contains?(content, "stack Haytni.PasswordPolicyPlugin")
      end
      # views
      assert_file "lib/haytni_web/views/haytni/#{scope}/session_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.SessionView do")
      end
      # templates
      assert_file "lib/haytni_web/templates/haytni/#{scope}/session/new.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_session_path(")
      end
      # shared templates
      assert_file "lib/haytni_web/templates/haytni/#{scope}/shared/keys.html.eex"
      assert_file "lib/haytni_web/templates/haytni/#{scope}/shared/message.html.eex"
      assert_file "lib/haytni_web/templates/haytni/#{scope}/shared/links.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_session_path(")
      end
      assert_file "lib/haytni_web/views/haytni/#{scope}/shared_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.SharedView do")
      end
      # migration
      assert [path] = Path.wildcard("priv/repo/migrations/*_haytni_authenticable_#{scope}_changes.ex")
      assert_file path, fn content ->
        assert String.contains?(content, ~s'def change(table \\\\ "#{table}") do')
        assert String.contains?(content, "defmodule Haytni.Migrations.#{camelized_scope}.AuthenticableCreation do")
      end
    else
      # TODO: refute_file
    end
    if Haytni.RegisterablePlugin in plugins do
      # views
      assert_file "lib/haytni_web/views/haytni/#{scope}/registration_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.RegistrationView do")
      end
      # templates
      assert_file "lib/haytni_web/templates/haytni/#{scope}/registration/new.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_registration_path(")
      end
      assert_file "lib/haytni_web/templates/haytni/#{scope}/registration/edit.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_registration_path(")
      end
    else
      # TODO: refute_file
    end
    if Haytni.TrackablePlugin in plugins do
      # migration
      assert [path] = Path.wildcard("priv/repo/migrations/*_haytni_trackable_#{scope}_changes.ex")
      assert_file path, fn content ->
        assert String.contains?(content, ~s'def change(table \\\\ "#{table}", scope \\\\ "#{scope}") do')
        assert String.contains?(content, "defmodule Haytni.Migrations.#{camelized_scope}.TrackableChanges do")
      end
    else
      # TODO: refute_file
    end
    if Haytni.RememberablePlugin in plugins do
      # migration
      assert [path] = Path.wildcard("priv/repo/migrations/*_haytni_rememberable_#{scope}_changes.ex")
      assert_file path, fn content ->
        assert String.contains?(content, ~s'def change(table \\\\ "#{table}") do')
        assert String.contains?(content, "defmodule Haytni.Migrations.#{camelized_scope}.RememberableChanges do")
      end
    else
      # TODO: refute_file
    end
    if Haytni.LockablePlugin in plugins do
      # views
      assert_file "lib/haytni_web/views/haytni/#{scope}/unlock_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.UnlockView do")
      end
      assert_file "lib/haytni_web/views/haytni/#{scope}/email/lockable_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.Email.LockableView do")
      end
      # templates
      assert_file "lib/haytni_web/templates/haytni/#{scope}/unlock/new.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_unlock_path(")
      end
      assert_file "lib/haytni_web/templates/haytni/#{scope}/email/lockable/unlock_instructions.text.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_unlock_url(")
      end
      assert_file "lib/haytni_web/templates/haytni/#{scope}/email/lockable/unlock_instructions.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_unlock_url(")
      end
      # migration
      assert [path] = Path.wildcard("priv/repo/migrations/*_haytni_lockable_#{scope}_changes.ex")
      assert_file path, fn content ->
        assert String.contains?(content, ~s'def change(table \\\\ "#{table}") do')
        assert String.contains?(content, "defmodule Haytni.Migrations.#{camelized_scope}.LockableChanges do")
      end
    else
      # TODO: refute_file
    end
    if Haytni.RecoverablePlugin in plugins do
      # views
      assert_file "lib/haytni_web/views/haytni/#{scope}/password_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.PasswordView do")
      end
      assert_file "lib/haytni_web/views/haytni/#{scope}/email/recoverable_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.Email.RecoverableView do")
      end
      # templates
      assert_file "lib/haytni_web/templates/haytni/#{scope}/password/new.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_password_path(")
      end
      assert_file "lib/haytni_web/templates/haytni/#{scope}/password/edit.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_password_path(")
      end
      assert_file "lib/haytni_web/templates/haytni/#{scope}/email/recoverable/reset_password_instructions.text.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_password_url(")
      end
      assert_file "lib/haytni_web/templates/haytni/#{scope}/email/recoverable/reset_password_instructions.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_password_url(")
      end
      # migration
      assert [path] = Path.wildcard("priv/repo/migrations/*_haytni_recoverable_#{scope}_changes.ex")
      assert_file path, fn content ->
        assert String.contains?(content, ~s'def change(table \\\\ "#{table}") do')
        assert String.contains?(content, "defmodule Haytni.Migrations.#{camelized_scope}.RecoverableChanges do")
      end
    else
      # TODO: refute_file
    end
    if Haytni.ConfirmablePlugin in plugins do
      # views
      assert_file "lib/haytni_web/views/haytni/#{scope}/confirmation_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.ConfirmationView do")
      end
      assert_file "lib/haytni_web/views/haytni/#{scope}/email/confirmable_view.ex", fn content ->
        assert String.contains?(content, "defmodule HaytniWeb.Haytni.#{camelized_scope}.Email.ConfirmableView do")
      end
      # templates
      assert_file "lib/haytni_web/templates/haytni/#{scope}/confirmation/new.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_confirmation_path(")
      end
      assert_file "lib/haytni_web/templates/haytni/#{scope}/email/confirmable/email_changed.text.eex"
      assert_file "lib/haytni_web/templates/haytni/#{scope}/email/confirmable/email_changed.html.eex"
      assert_file "lib/haytni_web/templates/haytni/#{scope}/email/confirmable/confirmation_instructions.text.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_confirmation_url(")
      end
      assert_file "lib/haytni_web/templates/haytni/#{scope}/email/confirmable/confirmation_instructions.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_confirmation_url(")
      end
      assert_file "lib/haytni_web/templates/haytni/#{scope}/email/confirmable/reconfirmation_instructions.text.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_confirmation_url(")
      end
      assert_file "lib/haytni_web/templates/haytni/#{scope}/email/confirmable/reconfirmation_instructions.html.eex", fn content ->
        assert String.contains?(content, "HaytniWeb.Router.Helpers.haytni_#{scope}_confirmation_url(")
      end
      # migration
      assert [path] = Path.wildcard("priv/repo/migrations/*_haytni_confirmable_#{scope}_changes.ex")
      assert_file path, fn content ->
        assert String.contains?(content, ~s'def change(table \\\\ "#{table}") do')
        assert String.contains?(content, "defmodule Haytni.Migrations.#{camelized_scope}.ConfirmableChanges do")
      end
    else
      # TODO: refute_file
    end
    """
    Enum.each(
      @plugins,
      fn plugin ->
        Enum.each(
          file_list_for(plugin, scope, table, camelized_scope),
          &(to_assertion(plugin in plugins, &1))
        )
      end
    )
  end

  describe "mix haytni.install" do
    setup do
      Mix.Task.clear()
      :ok
    end

    test "checks all necessary files are correctly generated for --plugins Haytni.AuthenticablePlugin --scope user --table users" do
      in_tmp_project(
        "haytni",
        fn ->
          capture_io( # TODO: do check_files, généré à partir de son paramètre plugins
            fn ->
              Mix.Tasks.Haytni.Install.run(~W[--plugin Haytni.AuthenticablePlugin])
            end
          )
          check_files([Haytni.AuthenticablePlugin], :user, "users")
        end
      )
    end

    test "checks all necessary files are correctly generated for --plugins Haytni.TrackablePlugin --scope foo --table bar" do
      in_tmp_project(
        "haytni",
        fn ->
          capture_io( # TODO: do check_files, généré à partir de son paramètre plugins
            fn ->
              Mix.Tasks.Haytni.Install.run(~W[--plugin Haytni.TrackablePlugin --scope foo --table bar])
            end
          )
          check_files([Haytni.TrackablePlugin], :foo, "bar")
        end
      )
    end

    test "checks all necessary files are correctly generated for all plugins --scope abc --table def" do
      in_tmp_project(
        "haytni",
        fn ->
          capture_io( # TODO: do check_files, généré à partir de son paramètre plugins
            fn ->
              Mix.Tasks.Haytni.Install.run(~W[--plugin Haytni.AuthenticablePlugin --plugin Haytni.RegisterablePlugin --plugin Haytni.RememberablePlugin --plugin Haytni.ConfirmablePlugin --plugin Haytni.LockablePlugin --plugin Haytni.RecoverablePlugin --plugin Haytni.TrackablePlugin --plugin Haytni.PasswordPolicyPlugin --scope abc --table def])
            end
          )
          check_files([Haytni.AuthenticablePlugin, Haytni.RegisterablePlugin, Haytni.RememberablePlugin, Haytni.ConfirmablePlugin, Haytni.LockablePlugin, Haytni.RecoverablePlugin, Haytni.TrackablePlugin, Haytni.PasswordPolicyPlugin], :abc, "def")
        end
      )
    end
  end
end
