defmodule Haytni.Helpers do
  @moduledoc ~S"""
  Regroup various helper functions that are not directly tied to the web part
  (mostly for plugins use but not in controllers, views or templates).
  """

  @doc ~S"""
  Convert a duration of the form `{number, unit}` to seconds.

  *unit* can be one of the following:
  - :second
  - :minute
  - :hour
  - :day
  - :week
  - :month
  - :year
  """
  @spec duration(duration :: pos_integer) :: pos_integer
  def duration(count)
    when is_number(count)
  do
    count
  end

  @spec duration({pos_integer, unit :: Haytni.duration_unit}) :: pos_integer
  def duration({count, :second}) do
    count
  end

  def duration({count, :minute}) do
    count * 60
  end

  def duration({count, :hour}) do
    count * 60 * 60
  end

  def duration({count, :day}) do
    count * 24 * 60 * 60
  end

  def duration({count, :week}) do
    count * 7 * 24 * 60 * 60
  end

  def duration({count, :month}) do
    count * 30 * 24 * 60 * 60
  end

  def duration({count, :year}) do
    count * 365 * 24 * 60 * 60
  end

  @doc ~S"""
  Helper to return the current UTC datetime as expected by `:utc_datetime` type of Ecto
  (meaning a %DateTime{} without microseconds).
  """
  @spec now() :: DateTime.t
  def now do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
  end

  @doc ~S"""
  Helper to add a global error under the `:base` key as Ruby on Rails does and right after apply
  (see `Ecto.Changeset.apply_action/2`) an action. Meaning the changeset is not meant to be reuse
  (you had better to use `add_base_error/2` instead), it is an immediate error.
  """
  @spec apply_base_error(changeset :: Ecto.Changeset.t, message :: String.t) :: {:error, Ecto.Changeset.t}
  def apply_base_error(changeset = %Ecto.Changeset{}, message) do
    changeset
    |> add_base_error(message)
    |> Ecto.Changeset.apply_action(:insert)
  end

  @doc ~S"""
  Helper to add a global error under the `:base` key as Ruby on Rails does.
  """
  @spec add_base_error(changeset :: Ecto.Changeset.t, message :: String.t) :: Ecto.Changeset.t
  def add_base_error(changeset = %Ecto.Changeset{}, message) do
    changeset
    |> Ecto.Changeset.add_error(:base, message)
  end

  @doc ~S"""
  Add the given *error* to all *keys* fields in *changeset* and returns the resulting as an error tuple (`{:error, %Ecto.Changeset{}}`)
  """
  @spec mark_changeset_keys_with_error(changeset :: Ecto.Changeset.t, keys :: [atom], error :: String.t) :: {:error, Ecto.Changeset.t}
  def mark_changeset_keys_with_error(changeset = %Ecto.Changeset{}, keys, error) do
    Enum.reduce(
      keys,
      changeset,
      fn field, changeset_as_acc ->
        Ecto.Changeset.add_error(changeset_as_acc, field, error)
      end
    )
    |> Ecto.Changeset.apply_action(:insert)
  end

  @doc ~S"""
  The translated string set as error when a key/field doesn't match any account
  """
  @spec no_match_message() :: String.t
  def no_match_message do
    import Haytni.Gettext

    dgettext("haytni", "doesn't match to any account")
  end

  @doc ~S"""
  Concat to *message* the translated note to invite the user to also check its spam folder
  """
  @spec concat_spam_check_hint_message(message :: String.t) :: String.t
  def concat_spam_check_hint_message(message) do
    import Haytni.Gettext

    [message, dgettext("haytni", "You may need to look at the spams folder.")]
    |> Enum.join("\n\n")
  end

  @doc ~S"""
  Helper for plugins to associate a mismatch error to fields given as *keys* of *changeset*.

  Returns an `Ecto.Changeset.t` with proper errors set.
  """
  @spec mark_changeset_keys_as_unmatched(changeset :: Ecto.Changeset.t, keys :: [atom]) :: {:error, Ecto.Changeset.t}
  def mark_changeset_keys_as_unmatched(changeset = %Ecto.Changeset{}, keys) do
    mark_changeset_keys_with_error(changeset, keys, no_match_message())
  end

  @doc ~S"""
  Casts the parameters received by a controller (a map of strings - as both keys and values) to a `%Ecto.Changeset{}`.
  This transformation is done by casting all values for *keys* to string and optionaly requiring (validation) the
  presence of *required_keys*.

  If *required_keys* is `nil`, all *keys* are mandatory.
  """
  @spec to_changeset(params :: %{optional(String.t) => String.t}, keys :: [atom], required_keys :: nil | [atom]) :: Ecto.Changeset.t
  def to_changeset(params, keys, required_keys \\ nil) do
    types = Enum.into(keys, %{}, fn key -> {key, :string} end)

    {%{}, types}
    |> Ecto.Changeset.cast(params, keys)
    |> Ecto.Changeset.validate_required(required_keys || keys)
  end

  @doc """
  Generates a module name by appending *suffix* to *module*

      iex> #{__MODULE__}.scope_module(YourApp.User, "Connection")
      YourApp.UserConnection
  """
  @spec scope_module(module :: module, suffix :: String.t) :: atom
  def scope_module(module, suffix) do
    module
    |> Module.split()
    |> List.update_at(-1, &(&1 <> suffix))
    |> Module.concat()
  end

  @doc ~S"""
  Helper intended for plugins for the implementation of their `build_config/1` callback. It merges the values of *params*
  into *struct*, their default configuration and automatically converting *duration_keys* from *Haytni.duration* to seconds.
  """
  @spec merge_config(struct :: struct, params :: %{optional(atom) => any} | Keyword.t, duration_keys :: [atom]) :: struct
  def merge_config(struct, params, duration_keys \\ []) do
    struct =
      params
      |> Enum.reduce(
        struct,
        fn {k, v}, acc ->
          Map.put(acc, k, v)
        end
      )

    duration_keys
    |> Enum.reduce(
      struct,
      fn k, acc ->
        Map.update!(acc, k, &duration/1)
      end
    )
  end
end
