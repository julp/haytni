?.?.?

- fix compatibility with ecto 3.0.0: `Multi.run` now passes Repo as first argument to the callback
- [Rememberable] fix pattern match, "remember me" feature was ignored

0.0.2

- phoenix 1.4/ecto 3.0 compatibility
- fix missing and untranslated strings in priv/templates/\*
- [Rememberable] set SameSite=Strict option on cookie
- [Lockable] fix FunctionClauseError due to missing call to HaytniWeb.Shared.add_referer_to_changeset
