# How to block disposable email addresses

The file lib/*your_app*/haytni/forbidden_email_providers.txt will contain one provider by line to reject.

Example:

```
foo
bar.com
```

In the following implementation, the pattern "foo" wil be considered, comparatively to a regular expression (but we directly use pattern matching) to: `^foo.*` on the hostname part of the email address.

Your plugin needs to implement both of the `validate_create_registration/2` and `validate_update_registration/2` callbacks.

Add the following code to your resource (lib/*your_app*/user.ex)

```elixir
# lib/your_app/haytni/refuse_disposable_email_plugin.ex
defmodule YourApp.RefuseDisposableEmailPlugin do
  use Haytni.Plugin
  #import YourApp.Gettext

  @external_resource providers_path = Path.join([__DIR__, "forbidden_email_providers.txt"])
  for line <- File.stream!(providers_path, [], :line) do
    provider = line
    |> String.trim_trailing()
    |> String.downcase()

    defp valid_email_provider?(unquote(provider) <> _rest), do: false
  end

  defp valid_email_provider?(_provider), do: true

  defp validate_email_provider(changeset = %Ecto.Changeset{valid?: true,  changes: %{email: email}}) do
    [_head, provider] = email
    |> String.downcase()
    |> String.split("@", parts: 2)

    if valid_email_provider?(provider) do
      changeset
    else
      add_error(changeset, :email, "disposable email addresses are not allowed") # better if you translate it with (d)gettext
    end
  end

  defp validate_email_provider(changeset = %Ecto.Changeset{}) do
    changeset
  end

  @impl Haytni.Plugin
  def validate_create_registration(changeset = %Ecto.Changeset{}, _config) do
    changeset
    |> validate_email_provider()
  end

  @impl Haytni.Plugin
  def validate_update_registration(changeset = %Ecto.Changeset{}, _config) do
    changeset
    |> validate_email_provider()
  end
end
```

Finally add `YourApp.RefuseDisposableEmailPlugin` to your Haytni stack key in lib/haytni.ex:

```elixir
# lib/your_app/haytni.ex
defmodule YourApp.Haytni do
  use Haytni, otp_app: :your_app

  # ...

  stack YourApp.RefuseDisposableEmailPlugin
end
```
