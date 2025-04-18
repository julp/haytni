**DISCLAIMER**: commands given to upgrade are purely informative, make sure to understand them and to do a backup of your project and database before running any of it, especially if your project is not (yet) versionned. (of course any improvement or rectification is welcome)

## ?.?.? (????-??-??)

- :gettext updated to 0.26
- fixed various depreciations:
  + `Mix.Config` => `Config`
  + collecting into a non-empty list
  + [LiveViewPlugin] `Phoenix.LiveView.get_connect_info/1` => `Phoenix.LiveView.get_connect_info/2`
- [Rememberable] fixed wrong cookie max-age value (expiration)
- fixed missing SQL negation in `Haytni.Token.purge_expired_tokens/1`, removing valid tokens instead of expired
- [Authenticable] added `sign_in_return_path` and `sign_out_return_path` options
- added `Haytni.send_email/2` to centralize emails sending
- experimental features:
  + added a module `Haytni.Callbacks` which defines the optional callbacks that a Haytni stack can define (override). Its only callback (for now) is `user_query/1` to compose the different Ecto queries loading users, a convenient way to (pre)load intimately related user data needed nearly everywhere (eg: roles - see guides for an example)
- fields `last_sign_in_at`/`current_sign_in_at` moved from Trackable to a new plugin called LastSeen
- added Anonymization plugin to modify configured fields on account deletion (automated soft deletion)
- added EncryptedEmail plugin to keep a hashed version of email address to avoid abuses without keeping the original address (RGPD compliant?)
- added Rolable plugin to import entire group/role support

Haytni doesn't directly rely on Bamboo anymore. Consequently, you'll need to add it as a dependency to your project (add `{:bamboo, "~> 2.2"}` to the `deps/0` function of your mix.exs file) and modify your mailer from `use Bamboo.Mailer, otp_app: :my_app` to `use Haytni.Mailer, otp_app: :my_app, adapter: Haytni.Mailer.BambooAdapter`. If you prefer, you can replace Bamboo in the same way (for Swoosh or whatever).

Commands to upgrade to comply with gettext 0.26:

```
# Phoenix < 1.7.0
find lib/my_app_web/views/ -type f -exec sed -i '' 's/require Haytni.Gettext/use Gettext, backend: Haytni.Gettext/g' {} \;
find lib/my_app_web/templates/ -type f -exec sed -i '' 's/Haytni.Gettext.dgettext("haytni",/dgettext("haytni",/g' {} \;
# Phoenix >= 1.7.0
find lib/my_app_web/controllers/haytni/ lib/my_app_web/emails/haytni/ -type f -exec sed -i '' 's/require Haytni.Gettext/use Gettext, backend: Haytni.Gettext/g' {} \;
find lib/my_app_web/controllers/haytni/ lib/my_app_web/emails/haytni/ -type f -exec sed -i '' 's/Haytni.Gettext.dgettext("haytni",/dgettext("haytni",/g' {} \;
```


## 0.7.0 (2022-04-10)

### Details

- unified tokens handling (inspired from phx_gen_auth)
  + add (authentication) support to channels (and, by extension, live view) if the *\_csrf\_token* cookie is not available
  + removal of:
    * fields
      + [Lockable] unlock_token
      + [Confirmable] confirmation_sent_at, confirmation_token, unconfirmed_email
      + [Rememberable] remember_token, remember_created_at
      + [Recoverable] reset_password_token, reset_password_sent_at
    * config
      + [Lockable] unlock_token_length
      + [Confirmable] confirmation_token_length
      + [Rememberable] remember_salt, remember_token_length
      + [Recoverable] reset_token_length
  + added:
    * config
      + [Lockable] unlock_within
- several Haytni modules cannot be stacked (raises if so)
- templates moved from EEx to HEEx (you can still use EEx)
- replaced :bcrypt_elixir with [:expassword](https://hex.pm/packages/expassword)([_bcrypt](https://hex.pm/packages/expassword_bcrypt))
- `Haytni.update_registration/4` has been changed to not handle email nor password changes at the same time: the single form and changeset used to edit its profile has been splitted in 3 separated changesets/forms. See priv/templates/registration/edit.html.heex on how to update this template. Consequently, the fields `:current_password`, `:email` and `:password` are no longer required to be whitelisted (`Ecto.Changeset.cast/4`) by your `update_registration_changeset/2` functions
- added new plugin [ClearSiteData] to set the HTTP header Clear-Site-Data as (and if) you want
- added support for LiveView 0.17: a Haytni stack (module) can be defined as a `on_mount/4` callback in `Phoenix.LiveView.Router.live_session/3` to set the current user from session
- [callbacks] added `c:Haytni.Plugin.on_delete_user/4`
- [callbacks] changed `c:Haytni.Plugin.routes/2` to `c:Haytni.Plugin.routes/3` (its arity) to get configuration datas of the plugin back

### Upgrade procedure

In mix.exs, replace the `:bcrypt_elixir` dependency by `{:expassword_bcrypt, "~> 0.2"}` and/or `{:expassword_argon2, "~> 0.2"}` (to support bcrypt and/or argon2). If you can't build a NIF on dev and/or test environment, you can instead use `:expassword_external_bcrypt`/`:expassword_external_argon2`.

Then the lines `stack Haytni.AuthenticablePlugin` need to be updated to specify, as options, how to hash passwords (new registrations or password changes) with `stack Haytni.AuthenticablePlugin, hashing_method: ExPassword.Bcrypt, hashing_options: %{cost: (if Mix.env() == :test, do: 4, else: 10)}` for bcrypt.

The following commands should handle the changes about reconfirmation:

```
find lib/your_app_web/templates/haytni/ -type f -name "*.eex" -print0 | xargs -0 perl -pi \
    -e 'BEGIN {undef $/}' \
    -e 's/<%= if \@config\.reconfirmable, do: \@user\.unconfirmed_email, else: \@user\.email %>/<%= \@user.email %>/g;' \
    -e 's/<%= if Haytni\.plugin_enabled\?\(\@module, Haytni\.ConfirmablePlugin\) && \@changeset\.data\.unconfirmed_email do %>.+?<% end %>//gs;'

find lib/your_app_web/templates/haytni/ -type f -name "reconfirmation_instructions.*.eex" -print0 | xargs -0 perl -pi -e 's/_confirmation_url/_reconfirmation_url/g;'
```

The following migration should take care of new tokens handling (removing old individual fields and creating the new table):

```elixir
# priv/repo/migrations/<current timestamp or custom version number>_haytni_upgrade_from_0_6_3_to_0_7_0.exs
defmodule YourRepo.Migrations.HaytniUpgradeFrom063To070 do
  @stacks [HaytniTestWeb.Haytni] # a list of your Haytni stacks (module names) related to the current Repo

  use Ecto.Migration

  def change do
    for stack <- @stacks do
      source = stack.schema().__schema__(:source)
      if Haytni.plugin_enabled?(stack, Haytni.RememberablePlugin) do
        drop_if_exists index(source, [:remember_token])
        alter table(source) do
          remove_if_exists :remember_token, :string, default: nil
          remove_if_exists :remember_created_at, :utc_datetime, default: nil
        end
      end

      if Haytni.plugin_enabled?(stack, Haytni.LockablePlugin) do
        drop_if_exists index(source, [:unlock_token])
        alter table(source) do
          remove_if_exists :unlock_token, :string, default: nil
        end
      end

      if Haytni.plugin_enabled?(stack, Haytni.RecoverablePlugin) do
        drop_if_exists index(source, [:reset_password_token])
        alter table(source) do
          remove_if_exists :reset_password_token, :string, default: nil
          remove_if_exists :reset_password_sent_at, :utc_datetime, default: nil
        end
      end

      if Haytni.plugin_enabled?(stack, Haytni.ConfirmablePlugin) do
        drop_if_exists index(source, [:confirmation_token])
        alter table(source) do
          remove_if_exists :unconfirmed_email, :string, default: nil
          remove_if_exists :confirmation_token, :string, default: nil
          remove_if_exists :confirmation_sent_at, :utc_datetime, null: false
        end
      end

      cistring = Haytni.Migration.case_insensitive_string_type()
      tokens_table = "#{source}_tokens"
      create table(tokens_table) do
        add :token, :binary, null: false
        add :user_id, references(source, on_delete: :delete_all, on_update: :update_all), null: false
        add :context, :string, null: false
        add :sent_to, cistring
        timestamps(updated_at: false, type: :utc_datetime)
      end

      create index(tokens_table, ~W[user_id]a)
      create unique_index(tokens_table, ~W[token context]a)
    end
  end
end
```


## 0.6.3 (2021-03-09)

### Details

- [Authenticable] added *inserted_at* field (`Ecto.Schema.timestamps/1` + `Ecto.Migration.timestamps/1`) to user schemas
- the X-Suspicious-Activity header is also set by HaytniWeb.Registerable.RegistrationController.create
- fixed `ON UPDATE CASCADE ON DELETE CASCADE` options in migrations on foreign keys (Trackable + Invitable)
- Bamboo updated to 2.0
- [callbacks] `on_logout/2` becomes `on_logout/3` to add *module* (Haytni stack's module)

### Upgrade procedure

The following migration should take care of the upgrade (except fixing the foreign keys options):

```elixir
# priv/repo/migrations/<current timestamp or custom version number>_haytni_upgrade_from_0_6_2_to_0_6_3.exs

defmodule YourRepo.Migrations.HaytniUpgradeFrom062To063 do
  @stacks [HaytniTestWeb.Haytni] # a list of your Haytni stacks (module names) related to the current Repo

  use Ecto.Migration

  def change do
    for stack <- @stacks do
      source = stack.schema().__schema__(:source)
      if Haytni.plugin_enabled?(stack, Haytni.AuthenticablePlugin) do
        alter table(source) do
          timestamps(updated_at: false, type: :utc_datetime, default: fragment("NOW()"))
        end
      end
    end
  end
end
```

The following command should handle the replacement of @user.(unlock_token|reset_password_token|confirmation_token|unconfirmed_email) to @\1 in email templates:

```
find lib/your_app_web/templates/haytni/ -type f -name "*.eex" -print0 | xargs -0 perl -pi \
    -e 's/\@user\.(unlock_token|reset_password_token|confirmation_token|unconfirmed_email)/\@\1/g;'
```


## 0.6.2 (2020-09-19)

- [Rememberable] fixed wrong checkbox's name in template session/new.html.eex
- fixed session was not created except if Rememberable was involved


## 0.6.1 (2020-09-05)

### Details

- introduced new Invitable plugin
- fix wrong extension for migrations (.ex => .exs)
- [Trackable] fixed table name (singular => plural, eg: user_connections becomes user**s**_connections)
- [Trackable] `Ecto.Schema.timestamps/1` type was changed from `:naive_datetime` to `:utc_datetime`
- [Trackable] no longer PostgreSQL specific but a "dummy" `VARCHAR(39)` will be used for storage for others RDBMS
- [Authenticable] DELETE method can be overriden for logout by giving the option `logout_method: :get` to your YourApp.Haytni.routes/1 call
- paths used to generate the routes created by plugins can be customized at your YourApp.Haytni.routes/1 call, see their respective documentation for further details
- [Lockable] Incrementation of failed_attempts has been moved into the *multi* to make the UPDATE atomic and makes this counter reliable
- routes created for Haytni are now prefixed by `haytni_<scope>_` to avoid conflicts and permit the use of several Haytni stacks (note that prefixes herited from Phoenix.Router.scope or outer Phoenix.Router.resources still apply)
- [callbacks] `files_to_install/0` becomes `files_to_install/4` to receive (in that order):
  1. *the base_path* (the lib/your_app directory)
  2. the *web_path* (the lib/your_app_web directory)
  3. the *scope*
  4. a timestamp (included in migration filenames)
- [Registerable] fix installation of edit.html.eex template, it was simply copied as is instead being evaluated as an EEx template like the others
- replaced `:string` for PostgreSQL by `:citext` on email addresses in migrations

### Upgrade procedure

- to keep your Haytni templates (both html and mail), you have to apply the following replacements: `\b(session|registration|unlock|confirmation|password)_(url|path)` to `haytni_<scope>_\1_\2` (`<scope>` has to match the scope defined in your config/\*.exs files, default is `user`). You can use a command like this one to make the changes:

```
find lib/your_app_web/ test/ -type f \( -name "*.ex" -o -name "*.eex" -o -name "*.exs" \) -print0 | xargs -0 perl -pi -e 's/\b(session|registration|unlock|confirmation|password)_(url|path)/haytni_user_\1_\2/g;'
```

- name of views (modules) have also be renamed to incorporate the scope in it: `(YourAppWeb\.Haytni\.)(\S*)View` becomes `\1<Scope>.\2View` **but** you can keep your old one if you want to share the exact same views **and** templates between several Haytni stacks. To perform the migration, **if needed**, you can also do it with some commands:

```
find lib/your_app_web/views/haytni -type f -name "*.ex" -print0 | xargs -0 perl -pi -e 's/\b(YourAppWeb\.Haytni\.)(\S*)View/\1User.\2View/g;'
(git) mv lib/your_app_web/views/haytni lib/your_app_web/views/temporary
mkdir lib/your_app_web/views/haytni
(git) mv lib/your_app_web/views/temporary lib/your_app_web/views/haytni/user
```

The following migration should take care of the upgrade of:

* email addresses to citext (PostgreSQL)
* rename your <scope>_connections tables (Trackable)

```elixir
# priv/repo/migrations/<current timestamp or custom version number>_haytni_upgrade_from_0_6_0_to_0_6_1.exs

defmodule YourRepo.Migrations.HaytniUpgradeFrom060To061 do
  @stacks [HaytniTestWeb.Haytni] # a list of your Haytni stacks (module names) related to the current Repo

  use Ecto.Migration

  def change do
    if repo().__adapter__() == Ecto.Adapters.Postgres do
      # DROP EXTENSION citext
      execute("CREATE EXTENSION IF NOT EXISTS citext", "")
    end

    for stack <- @stacks do
      source = stack.schema().__schema__(:source)

      if Haytni.plugin_enabled?(stack, Haytni.TrackablePlugin) do
        rename table("#{stack.scope()}_connections"), to: table("#{source}_connections")
      end

      if repo().__adapter__() == Ecto.Adapters.Postgres and (Haytni.plugin_enabled?(stack, Haytni.AuthenticablePlugin) or Haytni.plugin_enabled?(stack, Haytni.ConfirmablePlugin)) do
        alter table(source) do
          if Haytni.plugin_enabled?(stack, Haytni.AuthenticablePlugin) do
            modify :email, :citext, from: :string
          end
          if Haytni.plugin_enabled?(stack, Haytni.ConfirmablePlugin) do
            modify :unconfirmed_email, :citext, from: :string
          end
        end

        reindex_stmt = "REINDEX INDEX #{source}_email_index"
        execute(reindex_stmt, reindex_stmt)
      end
    end
  end
end
```


## 0.6.0 (2020-05-17)

- fix Mix.Project unavailable at runtime (application deployed without being recompiled)
- fix compatibility with ecto 3.0.0:
  + utc_datetime (Ecto type) fails with microseconds
  + `Multi.run` now passes Repo as first argument to the callback
- introduced new Trackable plugin (PostgreSQL specific)
- [Rememberable] fix pattern match on params, "remember me" feature was ignored
- [Rememberable] fix wrong cookie expiration (cookie was created expired)
- [Rememberable] fix error in `on_successful_authentication` when `remember_token` is `nil`
- [Authenticable] add `password_hash_fun` and `password_check_fun` options to use something else than bcrypt for passwords
- moved necessary calls to `Ecto.Changeset.validate_required/2` to [Registerable] instead of User schema `create_registration_changeset/2` and `update_registration_changeset/2` (this is its responsability)
- fix `Haytni.update_registration` trying to use an `%Ecto.Changeset{}` as second argument to `Ecto.Changeset.change/2`
- fix some Ecto.Changeset errors were not shown because no action was applied to them
- fix misspelled authenticat(e|ion)
- introduced new callback `validate_password/2` for custom/advanced password validation
- introduced new plugin `PasswordPolicyPlugin` to replace `Haytni.RegisterablePlugin` handling of `password_length` and to constrain password to contain at least `password_classes_to_match` among *digit*, *upper*/*lower* case letter and *other*
- [Recoverable] fix absence of validation on the newly defined password (no check on its length)
- `unlock_keys`, `reset_password_keys`, `authentication_keys`, `confirmation_keys` are not used at compile anymore (as `defstruct`)
- ~~different Haytni stacks can be used (this is partial, views and templates are still shared between those stacks for the moment, just make sure to call only one of them with `pipe_through` instead of `plug` in your router)~~
- removed (unused) scope parameter of routes callback
- session management (creation|removal) is moved from `Haytni.AuthenticablePlugin.find_user/3` and `HaytniWeb.Authenticable.SessionController.(create|delete)` to `Haytni.(find_user|logout)`
- per plugin configuration to avoid conflicts and testing
- [Registerable] added registration_disabled? parameter to disallow any new user registration
- set an HTTP header X-Suspicious-Activity: 1 (401 neither 403 status code are suitable for this) on authentication failure in order to offer the ability to a proxy to take action


## 0.0.2 (2019-05-14)

- phoenix 1.4/ecto 3.0 compatibility
- fix missing and untranslated strings in priv/templates/\*
- [Rememberable] set SameSite=Strict option on cookie
- [Lockable] fix FunctionClauseError due to missing call to HaytniWeb.Shared.add_referer_to_changeset
