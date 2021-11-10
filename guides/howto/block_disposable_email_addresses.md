# How to block disposable email addresses

The file lib/*your_app*/validations/forbidden_email_providers.txt will contain one provider (= what follows the `@` character) by line to reject.

Example:

```
foo
bar.com
```

In the following implementation, the pattern "foo" wil be considered, comparatively to a regular expression (but we directly use pattern matching) to: `^foo.*` on the hostname part of the email address.

Create lib/*your_app*/validations/email_provider_validation.ex with the following code:

```elixir
# lib/your_app/validations/email_provider_validation.ex
defmodule YourApp.EmailProviderValidation do
  import Ecto.Changeset
  #import YourApp.Gettext

  @external_resource providers_path = Path.join([__DIR__, "forbidden_email_providers.txt"])
  for line <- File.stream!(providers_path, [], :line) do
    provider =
      line
      |> String.trim_trailing()
      |> String.downcase()

    defp valid_email_provider?(unquote(provider) <> _rest), do: false
  end

  defp valid_email_provider?(_provider), do: true

  def validate_email_provider(%Ecto.Changeset{valid?: true} = changeset, field)
    when is_atom(field)
  do
    validate_change changeset, field, {:format, nil}, fn _, value ->
      [_head, provider] =
        value
        |> String.downcase()
        |> String.split("@", parts: 2)
      if valid_email_provider?(provider) do
        []
      else
        [{field, {"%{provider} is not allowed", provider: provider, validation: :format}}] # better if you translate it with (d)gettext
      end
    end
  end

  def validate_email_provider(changeset = %Ecto.Changeset{}, _field), do: changeset
end
```

Then edit lib/*your_app*/user.ex to add to the end of the functions `validate_create_registration/2` and `validate_update_registration/2`, the following line: `|> YourApp.EmailProviderValidation.validate_email_provider(:email)`

You can also write this functionnality as a plugin by implemenenting the `validate_create_registration/2` and `validate_update_registration/2` callbacks instead of modifying your lib/*your_app*/user.ex.

If so:

```elixir
# lib/your_app/haytni/refuse_disposable_email_plugin.ex
defmodule YourApp.RefuseDisposableEmailPlugin do
  use Haytni.Plugin

  @impl Haytni.Plugin
  def validate_create_registration(changeset = %Ecto.Changeset{}, _module, _config) do
    changeset
    |> YourApp.EmailProviderValidation(:email)
  end

  @impl Haytni.Plugin
  def validate_update_registration(changeset = %Ecto.Changeset{}, _module, _config) do
    changeset
    |> YourApp.EmailProviderValidation(:email)
  end
end
```

And register `YourApp.RefuseDisposableEmailPlugin` to your Haytni stack in your lib/*your_app*/haytni.ex:

```elixir
# lib/your_app/haytni.ex
defmodule YourApp.Haytni do
  use Haytni, otp_app: :your_app

  # ...

  stack YourApp.RefuseDisposableEmailPlugin
end
```

Note: this implementation does not check that the email address has a valid format, you need to check this point before (with `Ecto.Changeset.validate_format(changeset, :email, ~R/^[^@\s]+@[^@\s]+$/)` for example). Haytni already does it in RegisterablePlugin so, if you use it as a plugin, just call yours after RegisterablePlugin.
