defmodule Haytni.TrackablePlugin do
  @moduledoc ~S"""
  This module keeps tracks of the following elements:

    * the remote address IP used by the client at each of its sign in (in a table apart)
    * when he lastly signed in

  To do so a new module will be dynamically created by suffixing "Connection" to the module of your user's schema (eg: YourApp.User => YourApp.UserConnection)

  Fields:

    * last_sign_in_at (datetime@utc, nullable, default: `NULL`): date/time when the current session was started, `nil` if the user has never signed in
    * current_sign_in_at (datetime@utc, nullable, default: `NULL`): date/time when the previous session was started, `nil` if the user has never signed in at least twice

  Note that the previous fields can be `nil`, don't forget to handle this specific case!

  Configuration: none

  Routes: none
  """

  use Haytni.Plugin

  @impl Haytni.Plugin
  def files_to_install(_base_path, web_path, scope, timestamp) do
    [
      # migration
      {:eex, "migrations/0-trackable_changes.exs", Path.join([web_path, "..", "..", "priv", "repo", "migrations", "#{timestamp}_haytni_trackable_#{scope}_changes.exs"])},
    ]
  end

  def __after_compile__(env, _bytecode) do
    contents = quote do
      use Ecto.Schema
      import Ecto.Changeset

      schema "#{unquote(env.module.__schema__(:source))}_connections" do
        field :ip, unquote(Module.get_attribute(env.module, :__ip_type__))
        timestamps(updated_at: false, type: :utc_datetime)

        belongs_to unquote(String.to_atom(Phoenix.Naming.resource_name(env.module))), unquote(env.module)
      end

      @attributes ~W[ip]a
      def changeset(struct = %__MODULE__{}, params \\ %{}) do
        struct
        |> cast(params, @attributes)
        |> validate_required(@attributes)
      end
    end

    Module.create(env.module.__schema__(:association, :connections).related, contents, env)
  end

  @impl Haytni.Plugin
  def fields(module) do
    ip_type = case module.repo().__adapter__() do
      Ecto.Adapters.Postgres ->
        EctoNetwork.INET
      _ ->
        :string
    end

    quote bind_quoted: [ip_type: ip_type] do
      Module.put_attribute(__MODULE__, :__ip_type__, ip_type)

      @after_compile Haytni.TrackablePlugin

      field :last_sign_in_at, :utc_datetime
      field :current_sign_in_at, :utc_datetime

      has_many :connections, Haytni.Helpers.scope_module(__MODULE__, "Connection")
    end
  end

  @impl Haytni.Plugin
  def on_successful_authentication(conn = %Plug.Conn{}, user = %_{}, multi = %Ecto.Multi{}, keywords, _module, _config) do
    changes =
      keywords
      |> Keyword.put(:current_sign_in_at, Haytni.Helpers.now())
      |> Keyword.put(:last_sign_in_at, user.current_sign_in_at)

    # user.__struct__.__schema__(:association, :connections).related
    connection = Ecto.build_assoc(user, :connections)
    connection = connection.__struct__.changeset(connection, %{ip: to_string(:inet_parse.ntoa(conn.remote_ip))})

    {conn, Ecto.Multi.insert(multi, :connection, connection), changes}
  end

  defmodule QueryHelpers do
    @moduledoc ~S"""
    This module provides some basic helpers to query connections to be independant and not
    have to know the internals of the Trackable plugin.
    """

    import Ecto.Query

    @doc ~S"""
    Returns a queryable for all connections of *user*
    """
    @spec connections_from_user(user :: Haytni.user) :: Ecto.Query.t
    def connections_from_user(user = %_{}) do
      from(c in Ecto.assoc(user, :connections), as: :connections)
    end

    @doc ~S"""
    Returns a queryable for all invitations

    Note: *user* is not used for the query, just to find the scope/table/association
    """
    @spec connections_from_all(user :: Haytni.user) :: Ecto.Query.t
    def connections_from_all(user = %_{}) do
      from(c in user.__struct__.__schema__(:association, :connections).related, as: :connections)
    end

    @doc ~S"""
    Composes *query* to filter on ip address
    """
    @spec and_where_ip_equals(query :: Ecto.Queryable.t, ip :: String.t) :: Ecto.Query.t
    def and_where_ip_equals(query, ip) do
      from(c in query, where: c.ip == ^ip)
    end

    defmacrop inserted_at(query, value, op) do
      case op do
        :>= ->
          quote bind_quoted: [query: query, value: value] do
            case value do
              nil ->
                query
              %Date{} ->
                from(c in query, where: fragment("DATE(?)", c.inserted_at) >= type(^value, :date))
              %module{} when module in [DateTime, NaiveDateTime] ->
                from(c in query, where: c.inserted_at >= type(^value, :date))
            end
          end
        :<= ->
          quote bind_quoted: [query: query, value: value] do
            case value do
              nil ->
                query
              %Date{} ->
                from(c in query, where: fragment("DATE(?)", c.inserted_at) <= type(^value, :date))
              %module{} when module in [DateTime, NaiveDateTime] ->
                from(c in query, where: c.inserted_at <= type(^value, :date))
            end
          end
      end
    end

    @doc ~S"""
    Composes *query* to filter on connection date
    """
    @spec and_where_date_equals(query :: Ecto.Queryable.t, date :: Date.t | DateTime.t | NaiveDateTime.t) :: Ecto.Query.t
    def and_where_date_equals(query, date) do
      and_where_date_between(query, date, date)
    end

    @doc ~S"""
    Composes *query* to filter on connection between an interval
    """
    @spec and_where_date_between(query :: Ecto.Queryable.t, first :: nil | Date.t | DateTime.t | NaiveDateTime.t, last :: nil | Date.t | DateTime.t | NaiveDateTime.t) :: Ecto.Query.t
    def and_where_date_between(query, first, last) do
      query
      |> inserted_at(first, :>=)
      |> inserted_at(last, :<=)
    end
  end
end
