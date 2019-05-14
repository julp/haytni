# Haytni

Haytni is a configurable authentication system for Phoenix, inspired (and yet the word is weak) by Devise (should be almost compatible with it).

Goals:

* non-bloatware:
  + all logics are not located in controllers
  + minimize changes (upgrade)
* easily customisable and extendable:
  + enable (or disable) any plugin
  + add your own plugin(s) to the stack

Plugins:

* authenticable (`Haytni.AuthenticablePlugin`): handles hashing and storing an encrypted password in the database
* registerable (`Haytni.RegisterablePlugin`): the elements to create a new account or edit its own account
* rememberable (`Haytni.RememberablePlugin`): provides "persistent" authentification (the "remember me" feature)
* confirmable (`Haytni.ConfirmablePlugin`): accounts have to be validated by email
* recoverable (`Haytni.RecoverablePlugin`): recover for a forgotten password
* lockable (`Haytni.LockablePlugin`): automatic lock an account after a number of failed attempts to sign in
* trackable (`Haytni.TrackablePlugin`, only for PostgreSQL): register users's connections (IP + when)

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc) and published on [HexDocs](https://hexdocs.pm). Once published, the docs can be found at [https://hexdocs.pm/haytni](https://hexdocs.pm/haytni).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `haytni` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:haytni, "~> 0.0.2"},
    # ...
  ]
end
```

Run `mix deps.get`.

Configure Haytni *your_app*/config/config.exs

```
config :haytni,
  repo: YourApp.Repo,
  schema: YourApp.User,
  #mailer: YourApp.Mailer # see below
```


These are the mandatory options. See options of each plugin for full customizations.

Run `mix haytni.install` which has the following options (command arguments):
* `--table <table>` (default: `"users"`): the name of your table (used to generate migrations)
* `--plugin Module1 --plugin Module2 ... --plugin ModuleN` (default: value of `config :haytni, plugins: [...]`): the names of the (Elixir) modules/plugins to enable

Change *your_app*/lib/*your_app*_web/router.ex

```elixir
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  require Haytni # <= add this line

  # ...

  pipeline :browser do
    # ...

    plug Haytni.CurrentUserPlug # <= add this line
  end

  scope "/" do
    # ...

    Haytni.routes() # <= add this line
  end

  # ...

end
```

Change *your_app*/lib/*your_app*/user.ex

```elixir
defmodule YouApp.User do
  require Haytni # <= add this line

  # ...

  schema "..." do
    # ...

    Haytni.fields() # <= add this line
  end

  # ...

end
```

### Emails

For plugins which send emails (Confirmable, Lockable and Recoverable):

Create *your_app*/lib/mailer.ex as follows:

```elixir
defmodule YourApp.Mailer do
  use Bamboo.Mailer, otp_app: :your_app

  def from, do: {"mydomain.com", "noreply.mydomain.com"}
end
```

Add to *your_app*/lib/*your_app*_web/router.ex

```elixir
  if Mix.env() == :dev do
    Application.ensure_started(:bamboo)
    Application.spec(:bamboo, :vsn)
    |> to_string()
    |> Version.compare("0.8.0")
    |> case do
      :lt ->
        # Bamboo > 0.8
        forward "/sent_emails", Bamboo.SentEmailViewerPlug
      _ ->
        # Bamboo <= 0.8
        forward "/sent_emails", Bamboo.EmailPreviewPlug
    end
  end
```

Configure email sending in *your_app*/config/dev.exs:

```elixir
config :yourapp, YourApp.Mailer,
  adapter: Bamboo.LocalAdapter

config :haytni,
  mailer: YourApp.Mailer # <= add/change this line
```

For production (*your_app*/config/prod.exs): [see Bamboo's documentation](https://hexdocs.pm/bamboo/readme.html)

General configuration:

* `layout` (default: `false` for none): the layout to apply to Haytni's templates
* `plugins` (default: `[Haytni.AuthenticablePlugin, Haytni.RegisterablePlugin, Haytni.RememberablePlugin, Haytni.ConfirmablePlugin, Haytni.LockablePlugin, Haytni.RecoverablePlugin]`): a list of `Haytni.Plugin` modules to use

**Warning:** plugins order matters (in some case). Example: for correct handling of "automatic" authentification (find_user callback), Authenticable must appears before Rememberable in order to give precedence to the current session on the remember me cookie.

## Plugins

### Authenticable

Fields:

* email (string)
* encrypted_password (string)

Configuration:

* `authentication_keys` (default: `~W[email]a`): the key(s), in addition to the password, requested to login. You can redefine it to `~W[name]a`, for example, to ask the username instead of its email address.
* TODO: hashing algorithm/method (default: `bcrypt`)

Routes:

* `session_path` (actions: new/create)

### Registerable

Change *your_app*/lib/*your_app*/user.ex

```elixir
defmodule YourApp.User do
  # ...

  @attributes ~W[email password]a # add any field you'll may need
  # called when a user try to register himself
  def create_registration_changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, @attributes)
    |> validate_required(@attributes)
    # add any custom validation here
    |> Haytni.validate_create_registration()
  end

  # called when a user try to edit its own account (logic is completely different from registration)
  def update_registration_changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, ~W[email password current_password]a)
    # /!\ email and password are not necessarily required here /!\
    # add any custom validation here
    |> Haytni.validate_update_registration()
  end

  # ...
end
```

Configuration:

* `password_length` (default: `6..128`): define min and max password length as an Elixir Range
* `email_regexp` (default: `~R/^[^@\s]+@[^@\s]+$/`): the Regexp that an email at registration or profile edition needs to match
* `case_insensitive_keys` (default: `~W[email]a`): list of fields to automatically downcase on registration. May be unneeded depending on your database (eg: *citext* columns for PostgreSQL or columns with a collation suffixed by "\_ci" for MySQL)
* `strip_whitespace_keys` (default: `~W[email]a`): list of fields to automatically strip from whitespaces
* `email_index_name` (default: `"users_email_index"`): the name of the unique index/constraint on email field

Routes:

* `registration_path` (actions: new/create, edit/update)

### Rememberable

Fields:

* remember_token (string, nullable, unique, default: `NULL`): the token to sign in automatically (`NULL` if the account doesn't use this function)
* remember_created_at (datetime@utc, nullable, default: `NULL`): when the token was generated (also `NULL` if the account doesn't use this function)

Configuration:

* `remember_for` (default: `{2, :week}`): the period of validity of the token/which the user won't be asked for credentials
* `remember_salt` (default: `""`): the salt to (de)cipher the token stored in the (signed) cookie
* `remember_token_length` (default: 16): the length of the token (before being ciphered)
* `remember_cookie_name` (default: `"remember_token"`): the name of the cookie holding the token for automatic sign in
* `remember_cookie_options` (default: `[http_only: true]`): to set custom options of the cookie (options are: *domain*, *max_age*, *path*, *http_only*, *secure* and *extra*, see documentation of Plug.Conn.put_resp_cookie/4)

Routes: none

### Confirmable

Fields:

* confirmed_at (datetime@utc, nullable, default: `NULL`): when the account was confirmed else `NULL`
* confirmation_sent_at (datetime@utc): when the confirmation was sent
* confirmation_token (string, nullable, unique, default: `NULL`): the token to be confirmed if any pending confirmation (else `NULL`)
* unconfirmed_email (string, nullable, default: `NULL`): on email change the new email is stored here until its confirmation

Configuration:

* `reconfirmable` (default: `true`): if `true`, on an email change, the user has to confirm its new address
* `confirmation_keys` (default: `~W[email]a`): the key(s) to be matched before sending a new confirmation
* `confirm_within` (default: `{3, :day}`): delay after which confirmation token is considered as expired (ie the user has to ask for a new one)

Routes:

* `confirmation_path` (actions: show, new/create)

### Recoverable

Fields:

* reset_password_token (string, nullable, unique, default: `NULL`): the unique token to reinitialize the password (`NULL` if none)
* reset_password_sent_at (datetime@utc, nullable, default: `NULL`): when the reinitialization token was generated (also `NULL` if there is no pending request)

Configuration:

* `reset_token_length` (default: `32`): the length of the generated token
* `reset_password_within` (default: `{6, :hour}`): the delay before the token expires
* `reset_password_keys` (default: `~W[email]a`): the field(s) to be matched to send a reinitialization token

Routes:

* `password_path` (actions: new/create, edit/update)

### Lockable

Fields:

* failed_attempts (integer, default: `0`): the current count of successive failures to login
* locked_at (datetime@utc, nullable, default: `NULL`): when the account was locked (`NULL` while the account is not locked)
* unlock_token (string, nullable, unique, default: `NULL`): the token send to the user to unlock its account

Configuration:

* `maximum_attempts` (default: `20`): the amount of successive attempts to login before locking the corresponding account
* `unlock_token_length` (default: `32`): the length of the generated token
* `unlock_keys` (default: `~W[email]a`): the field(s) to match to accept the unlock request

Routes:

* `unlock_path` (actions: new/create, show)

### Trackable (PostgreSQL only)

Fields:

* `current_sign_in_at` (datetime@utc, nullable, default: `NULL`): the date/time of the last login of a user (`NULL` if he never used its account)
* `last_sign_in_at` (datetime@utc, nullable, default: `NULL`): the date/time of its previous login (`NULL` if the user signs in less than twice)

Configuration: none

Routes: none


## Quick recap

Functions you have to implement:

* for Registerable: *YourApp.User*.create_registration_changeset/2 and *YourApp.User*.update_registration_changeset/2
* for sending emails (plugins Confirmable, Lockable and Recoverable): *YourApp*.Mailer.from/0
