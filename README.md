# Haytni

Haytni is a configurable authentication system for Phoenix, inspired by Devise and `mix phx.gen.auth`

(end) goals:

* security focused
* provides a strong and ready to use base
* non-bloatware:
  + all logics are not located in controllers
  + minimize changes on upgrades
* easily customisable and extendable:
  + enable (or disable) any plugin
  + add your own plugins to the stack

The only things you install in your project are:

* migrations
* views (you may need some custom helpers for your templates)
* templates (for emails and web pages)

If you need your own features, you write (and test) your own plugins:

* no need to change some obscur and very long code you may not understand, you just need to implement the callbacks that feet your needs
* your changes will not impact and break anything else (starting by tests)


Important note: Haytni cannot be used in an umbrella-ed Phoenix application.


Plugins:

* [authenticable](https://hexdocs.pm/haytni/Haytni.AuthenticablePlugin.html) (`Haytni.AuthenticablePlugin`): handles hashing and storing an encrypted password in the database
* [registerable](https://hexdocs.pm/haytni/Haytni.RegisterablePlugin.html) (`Haytni.RegisterablePlugin`): the elements to create a new account or edit its own account
* [rememberable](https://hexdocs.pm/haytni/Haytni.RememberablePlugin.html) (`Haytni.RememberablePlugin`): provides "persistent" authentication (the "remember me" feature)
* [confirmable](https://hexdocs.pm/haytni/Haytni.ConfirmablePlugin.html) (`Haytni.ConfirmablePlugin`): accounts have to be validated by email
* [recoverable](https://hexdocs.pm/haytni/Haytni.RecoverablePlugin.html) (`Haytni.RecoverablePlugin`): recover for a forgotten password
* [lockable](https://hexdocs.pm/haytni/Haytni.LockablePlugin.html) (`Haytni.LockablePlugin`): automatic lock an account after a number of failed attempts to sign in
* [last_seen](https://hexdocs.pm/haytni/Haytni.LastSeenPlugin.html) (`Haytni.LastSeenPlugin`): register the last time a user signed in
* [trackable](https://hexdocs.pm/haytni/Haytni.TrackablePlugin.html) (`Haytni.TrackablePlugin`): register users's connections (the IP addresses he used)
* [invitable](https://hexdocs.pm/haytni/Haytni.InvitablePlugin.html) (`Haytni.InvitablePlugin`): registration on invitation or sponsorship
* [password policy](https://hexdocs.pm/haytni/Haytni.PasswordPolicyPlugin.html) (`Haytni.PasswordPolicyPlugin`): basic validations against passwords (length and minimal character types presence)
* [liveview](https://hexdocs.pm/haytni/Haytni.LiveViewPlugin.html) (`Haytni.LiveViewPlugin`): provides authentication to channels and liveview if the *\_csrf\_token* cookie is not available
* [clearsitedata](https://hexdocs.pm/haytni/Haytni.ClearSiteDataPlugin.html) (`Haytni.ClearSiteDataPlugin`): set the HTTP header Clear-Site-Data on logout (and eventually login)
* [encrypted_email](https://hexdocs.pm/haytni/Haytni.EncryptedEmailPlugin.html) (`Haytni.EncryptedEmailPlugin`): keep the email in an hashed form to prevent abuse (deleting the account then recreate it with same address)
* [anonymization](https://hexdocs.pm/haytni/Haytni.AnonymizationPlugin.html) (`Haytni.AnonymizationPlugin`): anonymize user's data on account deletion
* [rolable](https://hexdocs.pm/haytni/Haytni.RolablePlugin.html) (`Haytni.RolablePlugin`): everything (Ecto associations and management interface) you need to get roles support

Documentation can be found at [https://hexdocs.pm/haytni](https://hexdocs.pm/haytni).

Installation is described [here](https://hexdocs.pm/haytni/installation.html).

**BEWARE**: this README (and the whole master branch) might be out of sync with hexdocs (last release)
