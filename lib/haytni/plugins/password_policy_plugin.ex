defmodule Haytni.PasswordPolicyPlugin do
  @moduledoc ~S"""
  This plugin provides a basic password policy based on its length and its content (character types). If you are
  looking for a more advanced policy you'll probably want to disable this plugin and write your own.

  Fields: none

  Configuration:

    * `password_length` (default: `6..128`): define min and max password length as an Elixir Range
    * `password_classes_to_match` (default: `2`): the minimum character classes between digit, lowercase, uppercase and others a password has to match to be accepted

        stack Haytni.RegisterablePlugin,
          password_length: 6..128,
          password_classes_to_match: 2

  Routes: none
  """

  import Haytni.Gettext

  defmodule Config do
    defstruct password_length: 6..128,
      password_classes_to_match: 2

    @type t :: %__MODULE__{
      password_length: Range.t,
    }
  end

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
    Class.new(~R/\d/, dgettext("haytni", "a digit")),
    Class.new(~R/[[:lower:]]/, dgettext("haytni", "a lowercase letter")),
    Class.new(~R/[[:upper:]]/, dgettext("haytni", "a uppercase letter")),
    Class.new(~R/[^\d[:upper:][:lower:]]/, dgettext("haytni", "a different character")),
  ]

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    config = %Config{}
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
  @spec invalid_password_format_message(config :: Config.t) :: String.t
  def invalid_password_format_message(config) do
    dgettext(
      "haytni",
      "should contains at least %{count} character types among %{classes}",
      count: config.password_classes_to_match,
      classes: Enum.map(@classes, fn class -> Gettext.dgettext(Haytni.Gettext, "haytni", class.description) end)
        |> Enum.join(", ")
    )
  end

  @spec validate_password_content(changeset :: Ecto.Changeset.t, field :: atom, config :: Config.t) :: Ecto.Changeset.t
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
  def validate_password(changeset = %Ecto.Changeset{}, config) do
    #password = changeset.get_change(changeset, :password)
    changeset
    |> Ecto.Changeset.validate_length(@password_field, min: config.password_length.first, max: config.password_length.last)
    |> validate_password_content(@password_field, config)
  end
end
