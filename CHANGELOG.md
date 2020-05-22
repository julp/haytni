?.?.?

- [Authenticable] DELETE method can be overriden for logout by giving the option `logout_method: :get` to your YourApp.Haytni.routes/1 call
- paths used to generate the routes created by plugins can be customized at your YourApp.Haytni.routes/1 call, see their respective documentation for further details
- routes created for Haytni are now prefixed by `haytni_<scope>_` to avoid conflicts and permit the use of several Haytni stacks (note that prefixes herited from Phoenix.Router.scope or outer Phoenix.Router.resources still apply)
- `files_to_install/0` becomes `files_to_install/3` to receive the base_path (the lib/your_app directory), web_path (the lib/your_app_web directory) and scope

Upgrade notes:

- to keep your Haytni templates (both html and mail), you have to apply the following replacements: `\b(session|registration|unlock|confirmation|password)_(url|path)` to `haytni_<scope>_\1_\2` (`<scope>` has to match the scope defined in your config/\*.exs files, default is `user`). You can use a command like this one to make the changes:

```
find lib/your_app_web/ test/ -type f \( -name "*.ex" -o -name "*.eex" -o -name "*.exs" \) -print0 | xargs -0 perl -pi -e 's/\b(session|registration|unlock|confirmation|password)_(url|path)/haytni_user_\1_\2/'
```

- name of views (modules) have also be renamed to incorporate the scope in it: `(YourAppWeb\.Haytni\.)(\S*)View` becomes `\1<Scope>.\2View` **but** you can keep your old one if you want to share the exact same views **and** templates between several Haytni stacks. To perform the migration, **if needed**, you can also do it with some commands:

```
find lib/your_app_web/views/haytni -type f -name "*.ex" -print0 | xargs -0 perl -pi -e 's/\b(YourAppWeb\.Haytni\.)(\S*)View/\1User.\2View/'
(git) mv lib/your_app_web/views/haytni lib/your_app_web/views/temporary
mkdir lib/your_app_web/views/haytni
(git) mv lib/your_app_web/views/temporary lib/your_app_web/views/haytni/user
```

DISCLAIMER: these commands are purely informative, make sure to understand them and to do a backup of your project before running any of it, especially if your project is not (yet) versioned


0.6.0

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


0.0.2

- phoenix 1.4/ecto 3.0 compatibility
- fix missing and untranslated strings in priv/templates/\*
- [Rememberable] set SameSite=Strict option on cookie
- [Lockable] fix FunctionClauseError due to missing call to HaytniWeb.Shared.add_referer_to_changeset
