?.?.?


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
- moved necessary calls to `Ecto.Changeset.validate_required/2` to [Registerable] instead of User schema `create_registration_changeset/2` and `update_registration_changeset/2` (this is his responsability)
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
