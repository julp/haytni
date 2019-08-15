defmodule Haytni do
  @moduledoc ~S"""
  Documentation for Haytni.
  """

  @application :haytni

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
  def duration(count)
    when is_number(count)
  do
    count
  end

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

  defp otp_app do
    Application.fetch_env!(@application, :otp_app)
  end

  defp app_base(app) do
    case Application.get_env(app, :namespace, app) do
      ^app -> app |> to_string |> Phoenix.Naming.camelize()
      mod  -> mod |> inspect()
    end
  end

  def web_module do
    otp_app()
    |> app_base()
    |> Kernel.<>("Web")
  end

  @spec router() :: module
  def router do
    Module.concat([Haytni.web_module(), :Router, :Helpers])
  end

  @spec endpoint() :: module
  def endpoint do
    Module.concat([Haytni.web_module(), :Endpoint])
  end

  def fetch_config(key, default \\ nil) do
    case Application.get_env(@application, key, default) do
      {:system, variable} ->
        System.get_env(variable)
      value ->
        value
    end
  end

  use Haytni.Config, [
    layout: false,
    plugins: [
      Haytni.AuthenticablePlugin,
      Haytni.RegisterablePlugin,
      Haytni.RememberablePlugin,
      Haytni.ConfirmablePlugin,
      Haytni.LockablePlugin,
      Haytni.RecoverablePlugin
    ]
  ]

  @spec plugin_enabled?(module :: module) :: boolean
  def plugin_enabled?(module) do
    module in plugins()
  end

  @doc ~S"""
  Returns the mailer from application's configuration

      config :your_app, :haytni,
        mailer: YourApp.Mailer
  """
  def mailer do
    Application.fetch_env!(@application, :mailer)
  end

  @doc ~S"""
  Returns the user's schema from application's configuration

      config :your_app, :haytni,
        schema: YourApp.User
  """
  def schema do
    Application.fetch_env!(@application, :schema)
  end

  @doc ~S"""
  Returns the repo (implements Ecto.Repo) from application's configuration

      config :your_app, :haytni,
        schema: YourApp.Repo
  """
  def repo do
    Application.fetch_env!(@application, :repo)
  end

  # Returns the first non-falsy (`nil` in particular) resulting of calling *fun* for each element of *list* or *default* if all elements of *list* returned a falsy value.
  defp map_while(list, default, fun) do
    try do
      for el <- list do
        v = fun.(el)
        if v do
          throw v
        end
      end
    catch
      val ->
        val
    else
      _ ->
        default
    end
  end

  defp find_user([hd | tl], conn) do
    result = {conn, user} = hd.find_user(conn)
    if user do
      result
    else
      find_user(tl, conn)
    end
  end

  defp find_user([], conn) do
    {conn, nil}
  end

  @doc ~S"""
  Used by plug to extract the current user (if any) from the HTTP
  request (meaning from headers, cookies or session)
  """
  @spec find_user(conn :: Plug.Conn.t) :: {Plug.Conn.t, struct | nil}
  def find_user(conn = %Plug.Conn{}) do
    result = {conn, user} = find_user(plugins(), conn)
    if user do
      case map_while(plugins(), false, &(&1.invalid?(user))) do
        {:error, _error} ->
          {conn, nil}
        false ->
          result
      end
    else
      {conn, nil}
    end
  end

  @doc ~S"""
  Register user from controller's *params*.

  Returned value is one of:
    * `{:ok, map}` where *map* is the result of the internals `Ecto.Multi.*` calls
    * `{:error, failed_operation, result_of_failed_operation, changes_so_far}` with:
      + *failed_operation*: the name of the operation which failed
      + *result_of_failed_operation*: its result/returned value
      + *changes_so_far*: same as *map* of the `{:ok, map}` case

  The inserted user will be part of *map* (or eventualy *changes_so_far*) under the key `:user`.

  See `Ecto.Repo.insert/3` for *options*.
  """
  @spec create_user(attrs :: map, options :: Keyword.t) :: {:ok, %{Ecto.Multi.name => any}} | {:error, Ecto.Multi.name, any, %{Ecto.Multi.name => any}}
  def create_user(attrs = %{}, options \\ []) do
    schema = schema()
    changeset = schema
    |> struct()
    |> schema.create_registration_changeset(attrs)

    multi = Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, changeset, options)

    plugins()
    |> Enum.reduce(multi, fn module, multi_as_acc -> module.on_registration(multi_as_acc) end)
    |> repo().transaction()
  end

  @spec handle_email_change(multi :: Ecto.Multi.t, changeset :: Ecto.Changeset.t) :: Ecto.Multi.t
  defp handle_email_change(multi = %Ecto.Multi{}, changeset = %Ecto.Changeset{changes: %{email: new_email}}) do
    multi = multi
    |> Ecto.Multi.run(:new_email, fn _repo, %{} ->
      {:ok, new_email}
    end)
    |> Ecto.Multi.run(:old_email, fn _repo, %{} ->
      {:ok, changeset.data.email}
    end)
    plugins()
    |> Enum.reduce({multi, changeset}, fn module, {multi = %Ecto.Multi{}, changeset = %Ecto.Changeset{}} -> module.on_email_change(multi, changeset) end)
  end

  defp handle_email_change(multi = %Ecto.Multi{}, changeset = %Ecto.Changeset{}), do: {multi, changeset}

  @doc ~S"""
  Update user's registration, its own registration.

  Works exactly as `create_user`. The only difference is the additionnal parameter: the user to update as first one.

  NOTE: the callbacks of `Ecto.Multi.run` added to the multi by the `on_email_change/2` callback will receive from the
  `Map` they get as their (single) argument the following predefined elements:

    * the updated user as the `:user` key
    * the previous email as `:old_email`
    * `:new_email`: the new email
  """
  @spec update_registration(user :: struct, attrs :: map, options :: Keyword.t) :: {:ok, %{Ecto.Multi.name => any}} | {:error, Ecto.Multi.name, any, %{Ecto.Multi.name => any}}
  def update_registration(user = %_{}, attrs = %{}, options \\ []) do
    changeset = user
    |> schema().update_registration_changeset(attrs)
    {multi = %Ecto.Multi{}, changes} = Ecto.Multi.new()
    |> handle_email_change(changeset)
    # update changeset with changes returned from plugins
    changeset = Ecto.Changeset.change(changes)
    # create a multi to update user and merge into it the multi from plugins then execute it
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset, options)
    |> Ecto.Multi.append(multi)
    |> repo().transaction()
  end

  @doc ~S"""
  Injects the necessary routes for enabled plugins into your Router
  """
  defmacro routes(options \\ []) do
    scope = Keyword.get(options, :scope, :user)
    plugins()
    |> Enum.map(&(&1.routes(scope, options)))
  end

  @doc ~S"""
  Injects `Ecto.Schema.field`s necessary to enabled plugins into your User schema
  """
  defmacro fields do
    plugins()
    |> Enum.map(&(&1.fields()))
  end

  @doc ~S"""
  Notifies plugins that current user is going to be logged out
  """
  @spec logout(conn :: Plug.Conn.t) :: Plug.Conn.t
  def logout(conn = %Plug.Conn{}) do
    plugins()
    |> Enum.reverse()
    |> Enum.reduce(conn, fn module, conn -> module.on_logout(conn) end)
  end

  @doc ~S"""
  To be called on (manual) login
  """
  @spec login(conn :: Plug.Conn.t, user :: struct) :: {:ok, Plug.Conn.t} | {:error, String.t}
  def login(conn = %Plug.Conn{}, user = %_{}) do
    case map_while(plugins(), false, &(&1.invalid?(user))) do
      error = {:error, _message} ->
        error
      false ->
        {conn, _user, keyword} = plugins()
        |> Enum.reduce({conn, user, Keyword.new()}, fn module, {conn, user, keyword} -> module.on_successful_authentification(conn, user, keyword) end)
        update_user_with!(user, keyword)
        {:ok, Plug.Conn.assign(conn, :current_user, user)}
    end
  end

  @doc ~S"""
  Notifies plugins that the authentification failed for *user*.

  If *user* is `nil`, nothing is done.
  """
  @spec authentification_failed(user :: struct | nil) :: nil
  def authentification_failed(user = nil) do
    # NOP, for convenience
    user
  end

  def authentification_failed(user = %_{}) do
    changes = plugins()
    |> Enum.reduce(Keyword.new(), fn plugin, keywords -> plugin.on_failed_authentification(user, keywords) end)
    update_user_with!(user, changes)
  end

  @doc ~S"""
  This function is a callback to be called from your `User.create_registration_changeset/2` so validations
  and others internal tasks can be done by plugins at user's registration.
  """
  @spec validate_create_registration(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  def validate_create_registration(changeset = %Ecto.Changeset{}) do
    plugins()
    |> Enum.reduce(changeset, fn module, changeset -> module.validate_create_registration(changeset) end)
  end

  @doc ~S"""
  Same than `validate_update_registration/2` but at registration's edition.
  """
  @spec validate_update_registration(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  def validate_update_registration(changeset = %Ecto.Changeset{}) do
    plugins()
    |> Enum.reduce(changeset, fn module, changeset -> module.validate_update_registration(changeset) end)
  end

  defp user_and_changes_to_changeset(user, changes) do
    Ecto.Changeset.change(user, changes)
  end

  @doc ~S"""
  Update the given user from a list of changes as `Keyword`.

  Returns `{:error, changeset}`  if there was a validation or a known constraint error else `{:ok, struct}`
  where *struct* is the updated user.

  NOTE: for internal use, there isn't any validation. Do **NOT** inject values from controller's *params*!
  """
  @spec update_user_with(user :: struct, changes :: Keyword.t) :: {:ok, struct} | {:error, Ecto.Changeset.t}
  def update_user_with(user = %_{}, changes) do
    user_and_changes_to_changeset(user, changes)
    |> Haytni.repo().update()
  end

  @doc ~S"""
  Same as `update_user_with/2` but returns the updated *user* struct or raises if *changes* are invalid.
  """
  @spec update_user_with!(user :: struct, changes :: Keyword.t) :: struct | no_return
  def update_user_with!(user = %_{}, changes) do
    user_and_changes_to_changeset(user, changes)
    |> Haytni.repo().update!()
  end

  @doc ~S"""
  Helper for plugins to associate a mismatch error to fields given as *keys* of *changeset*.

  Returns an `Ecto.Changeset.t` with proper errors set.
  """
  @spec mark_changeset_keys_as_unmatched(changeset :: Ecto.Changeset.t, keys :: [atom]) :: Ecto.Changeset.t
  def mark_changeset_keys_as_unmatched(changeset = %Ecto.Changeset{}, keys) do
    import Haytni.Gettext

    Enum.reduce(keys, changeset, fn field, changeset_as_acc ->
      Ecto.Changeset.add_error(changeset_as_acc, field, dgettext("haytni", "doesn't match to any account"))
    end)
    |> Map.put(:action, :insert)
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
end
