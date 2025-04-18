defmodule Haytni.PasswordPolicyPlugin do
  @default_password_length 6..128
  @default_password_classes_to_match 2

  @moduledoc """
  This plugin provides a basic password policy based on its length and its content (character types). If you are
  looking for a more advanced policy you'll probably want to disable this plugin and write your own.

  Fields: none

  Configuration:

    * `password_length` (default: `#{inspect(@default_password_length)}`): define min and max password length as an Elixir Range. It's worth noting, if you use bcrypt to hash passwords, that there is no point to
      allow a length beyond 72 bytes because bcrypt silently truncates keys to this length.
    * `password_classes_to_match` (default: `#{inspect(@default_password_classes_to_match)}`): the minimum character classes between digit, lowercase, uppercase and others a password has to match to be accepted

          stack #{inspect(__MODULE__)},
            password_length: #{inspect(@default_password_length)},
            password_classes_to_match: #{inspect(@default_password_classes_to_match)}

  Routes: none
  """

  use Gettext, backend: Haytni.Gettext

  defstruct [
    password_length: @default_password_length,
    password_classes_to_match: @default_password_classes_to_match,
  ]

  @type t :: %__MODULE__{
    password_length: Range.t,
  }

  use Haytni.Plugin

  defmodule Class do
    @moduledoc false

    defstruct ~W[pattern description]a

    @type t :: %__MODULE__{
      pattern: Regex.t,
      description: String.t,
    }

    def new(pattern, description) do
      %__MODULE__{pattern: pattern, description: description}
    end
  end

  @password_field :password
  @classes [
    Class.new(~r/\d/, dgettext_noop("haytni", "a digit")),
    Class.new(~r/[[:lower:]]/, dgettext_noop("haytni", "a lowercase letter")),
    Class.new(~r/[[:upper:]]/, dgettext_noop("haytni", "a uppercase letter")),
    Class.new(~r/[^\d[:upper:][:lower:]]/, dgettext_noop("haytni", "a different character")),
  ]

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    config =
      %__MODULE__{}
      |> Haytni.Helpers.merge_config(options)

    if config.password_classes_to_match > length(@classes) do
      raise ArgumentError, "password_classes_to_match was overriden to #{config.password_classes_to_match} but it cannot be greater than #{length(@classes)}"
    end

    config
  end

  @doc ~S"""
  The translated string to display when the password doesn't contain at least `config.password_classes_to_match`
  different types of characters in it.
  """
  @spec invalid_password_format_message(config :: t) :: String.t
  def invalid_password_format_message(config) do
    dgettext(
      "haytni",
      "should contains at least %{count} character types among %{classes}",
      count: config.password_classes_to_match,
      classes:
        @classes
        |> Enum.map(fn class -> Gettext.dgettext(Haytni.Gettext, "haytni", class.description) end)
        |> Enum.join(", ")
    )
  end

  @spec validate_password_content(changeset :: Ecto.Changeset.t, field :: atom, config :: t) :: Ecto.Changeset.t
  defp validate_password_content(%Ecto.Changeset{valid?: false} = changeset, field, _config)
    when is_atom(field)
  do
    changeset
  end

  defp validate_password_content(%Ecto.Changeset{} = changeset, field, config)
    when is_atom(field)
  do
    Ecto.Changeset.validate_change changeset, field, {:format, nil}, fn _, value ->
      if config.password_classes_to_match > Enum.count(@classes, fn class -> value =~ class.pattern end) do
        [{field, {invalid_password_format_message(config), [validation: :format]}}]
      else
        []
      end
    end
  end

  @impl Haytni.Plugin
  def validate_password(changeset = %Ecto.Changeset{}, _module, config) do
    #password = changeset.get_change(changeset, :password)
    changeset
    |> Ecto.Changeset.validate_length(@password_field, min: config.password_length.first, max: config.password_length.last)
    |> validate_password_content(@password_field, config)
  end
end
