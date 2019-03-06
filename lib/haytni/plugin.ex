defmodule Haytni.Plugin do
  @moduledoc ~S"""
  Defines a plugin to be used by Haytni
  """

  @doc ~S"""
  This callback let you do any kind of change or additionnal validation on the changeset
  when a user is registering.
  """
  @callback validate_create_registration(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t

  @doc ~S"""
  Same as `validate_create_registration` but registration's edition as logic between the two
  may be completely different.
  """
  @callback validate_update_registration(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t

  @doc ~S"""
  Returns the `Ecto.Schema.field/1`s as a quoted fragment to be injected in application's Router
  """
  @callback fields() :: Macro.t

  @doc ~S"""
  Returns the routes as a quoted fragment to be injected in application's Router
  """
  @callback routes(scope :: atom, options :: Keyword.t) :: Macro.t

  @doc ~S"""
  Returns a list of files to be (un)installed by the mix tasks haytni.(un)install

  # TODO: format of the list
  """
  @callback files_to_install() :: []

  @doc ~S"""
  Extract (early) the user from the HTTP request (http authentification, cookies/session, ...).

  Returns a tuple of the form `{conn, user}` with user being `nil` if no user could be found at
  this early stage.
  """
  @callback find_user(conn :: Plug.Conn.t) :: {Plug.Conn.t, struct | nil}

  @doc ~S"""
  Check if the user is in a valid state. This callback is intended to let know others plugins
  if we should reject the login (and why).

  Returns `false` if the user is allowed to login else `{:error, reason}` where *reason* is a string,
  an informative to be directly served to the end user.

  For example, you may want to have some kind of ban plugin. This is the way to decline the login:

      def invalid?(%{banned: true}), do: {:error, :banned} # or: {:error, dgettext("myapp", "you're banned")}
      def invalid?(%{banned: _}), do: false
  """
  @callback invalid?(user :: struct) :: false | {:error, atom}

  @doc ~S"""
  This callback is invoked when a user (manually) log out. Its purpose is mainly to do some cleanup
  like removing a cookie.
  """
  @callback on_logout(conn :: Plug.Conn.t) :: Plug.Conn.t # TODO: or {Plug.Conn.t, Keyword.t} to update the user ?

  @doc ~S"""
  Invoked when an authentification failed (wrong password). It receives the concerned account
  and a Keyword to return after updating it if any change have to be done to this user.

  For example, you can use it as follows to count the number of failed attempts to login:

      def on_failed_authentification(user = %_{}, keyword) do
        Keyword.put(keyword, :failed_attempts, user.failed_attempts + 1)
      end

  Note: we choose to use and pass *keyword* as an accumulator to let the possibility to plugins
  to deal themselves on a conflict (several different plugins which want to alter a same field).
  Even if `Keyword` allows a same key to be defined several times, you'll probably don't want it
  to happen as the last defined value for a given key will (silently) override the others.
  """
  @callback on_failed_authentification(user :: struct | nil, keywords :: Keyword.t) :: Keyword.t

  @doc ~S"""
  Invoked when an authentification is successful. Like `on_failed_authentification/2`, it receives
  the current user and a Keyword to return after updating it if you want to bring any change to this
  user to the database.

  To continue our example with a failed attempts counter, on a successful authentification it may be
  a good idea to reset it in this scenario:

      def on_successful_authentification(conn = %Plug.Conn{}, user = %_{}, keywords) do
        {conn, user, Keyword.put(keywords, :failed_attempts, 0)}
      end
  """
  @callback on_successful_authentification(conn :: Plug.Conn.t, user :: struct, keywords :: Keyword.t) :: {Plug.Conn.t, struct, Keyword.t}

  @doc ~S"""
  This callback is invoked when a user is editing its registration and change its email address.
  It is a facility (subset) to avoid you to handle it by yourself via `validate_update_registration/1`.

  It returns a tuple of `{Ecto.Multi, Ecto.Changeset}`, same as its arguments, to permit to the
  callback to add any operation to *multi* or change to *changeset*.

  This callback is called **before** updating the user but the actions added to *multi* will be
  run **after** its update.
  """
  @callback on_email_change(multi :: Ecto.Multi.t, changeset :: Ecto.Changeset.t) :: {Ecto.Multi.t, Ecto.Changeset.t}

  @doc ~S"""
  Invoked to accomplish a task right after user's registration (insert). This callback allows you
  to do some linked changes to the database, send an email or whatever by appending it to *multi*.

  Remember to comply to `Ecto.Multi` functions. In particular `Ecto.Multi.run`: the function
  called by it have to return `{:ok, your value}` or `{:error, your value}`. Also note that
  the inserted user will be passed to the function called by `Ecto.Multi.run` as the `:user`
  key to the map received by the last one as its (only) argument.

  The following example illustrate how to send a welcome mail:

      def on_registration(multi = %Ecto.Multi{}) do
        multi
        |> Ecto.Multi.run(:send_welcome_email, fn %{user: user} ->
          send_welcome_email_to(user)
          {:ok, :success}
        end)
      end
  """
  @callback on_registration(multi :: Ecto.Multi.t) :: Ecto.Multi.t

if false do
  @callback shared_links(atom :: atom) :: []
end

  #@callback on_session_start(conn :: Plug.Conn.t, user :: struct) :: Plug.Conn.t

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      @behaviour unquote(__MODULE__)

      def fields do
        quote do
        end
      end

      def routes(_scope, _options) do
        quote do
        end
      end

if false do
      def shared_links(_), do: []
end
      def invalid?(_user = %_{}), do: false
      def find_user(conn = %Plug.Conn{}), do: {conn, nil}
      def on_failed_authentification(_user = %_{}, keywords), do: keywords
      def files_to_install(), do: []
      def on_logout(conn = %Plug.Conn{}), do: conn
      def on_registration(multi = %Ecto.Multi{}), do: multi
      def validate_create_registration(changeset = %Ecto.Changeset{}), do: changeset
      def validate_update_registration(changeset = %Ecto.Changeset{}), do: changeset
      def on_email_change(multi = %Ecto.Multi{}, changeset = %Ecto.Changeset{}), do: {multi, changeset}
      def on_successful_authentification(conn = %Plug.Conn{}, user = %_{}, keywords), do: {conn, user, keywords}

      defoverridable [
        fields: 0,
        routes: 2,
        invalid?: 1,
        find_user: 1,
        on_logout: 1,
        #shared_links: 1,
        on_registration: 1,
        on_email_change: 2,
        files_to_install: 0,
        on_failed_authentification: 2,
        on_successful_authentification: 3,
        validate_create_registration: 1,
        validate_update_registration: 1
      ]
    end
  end
end
