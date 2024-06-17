defmodule Haytni.TrackablePlugin do
  @default_on_delete nil

  @moduledoc """
  This module keeps tracks of the following elements:

    * the remote address IP used by the client at each of its sign in (in a table apart)
    * when he lastly signed in

  To do so a new module will be dynamically created by suffixing "Connection" to the module of your user's schema (eg: YourApp.User => YourApp.UserConnection)

  Fields:

    * last_sign_in_at (datetime@utc, nullable, default: `NULL`): date/time when the current session was started, `nil` if the user has never signed in
    * current_sign_in_at (datetime@utc, nullable, default: `NULL`): date/time when the previous session was started, `nil` if the user has never signed in at least twice

  Note that the previous fields can be `nil`, don't forget to handle this specific case!

  Configuration:

    * `:on_delete` (default: `#{inspect(@default_on_delete)}`): what to do regarding the connections on user deletion. Possible values:

      + `:soft_cascade` to delete all connections related to the user being removed. Use it only if you don't want to keep these data and soft delete the user (else just rely on
        the `ON DELETE CASCADE` option of the foreign key)
      + `nil` (or any other value) does nothing

  Routes: none
  """

  defstruct [
    on_delete: @default_on_delete,
  ]

  @type t :: %__MODULE__{
    on_delete: nil | :soft_cascade,
  }

  use Haytni.Plugin

  @impl Haytni.Plugin
  def build_config(options \\ %{}) do
    %__MODULE__{}
    |> Haytni.Helpers.merge_config(options)
  end

  @impl Haytni.Plugin
  def files_to_install(_base_path, web_path, scope, timestamp) do
    [
      # migration
      {:eex, "migrations/0-trackable_changes.exs", Path.join([web_path, "..", "..", "priv", "repo", "migrations", "#{timestamp}_haytni_trackable_#{scope}_changes.exs"])},
    ]
  end

  def __after_compile__(env, _bytecode) do
    contents =
      quote do
        use Ecto.Schema
        import Ecto.Changeset

        schema unquote("#{env.module.__schema__(:source)}_connections") do
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

  @spec field_ip_type_from_adapter(module) :: atom
  defp field_ip_type_from_adapter(Ecto.Adapters.Postgres), do: EctoNetwork.INET
  defp field_ip_type_from_adapter(_), do: :string

  @impl Haytni.Plugin
  def fields(module) do
    ip_type = module.repo().__adapter__() |> field_ip_type_from_adapter()

    quote bind_quoted: [ip_type: ip_type] do
      Module.put_attribute(__MODULE__, :__ip_type__, ip_type)

      @after_compile Haytni.TrackablePlugin

      field :last_sign_in_at, :utc_datetime
      field :current_sign_in_at, :utc_datetime

      has_many :connections, Haytni.Helpers.scope_module(__MODULE__, "Connection")
    end
  end

  @spec add_connection_to_multi(multi :: Ecto.Multi.t, conn :: Plug.Conn.t, user :: Haytni.user) :: Ecto.Multi.t
  defp add_connection_to_multi(multi = %Ecto.Multi{}, conn = %Plug.Conn{}, user = %_{}) do
    # user.__struct__.__schema__(:association, :connections).related
    connection = Ecto.build_assoc(user, :connections)
    connection = connection.__struct__.changeset(connection, %{ip: to_string(:inet_parse.ntoa(conn.remote_ip))})

    Ecto.Multi.insert(multi, :connection, connection)
  end

if false do
  # TODO: requires conn (%Plug.Conn{})
  @impl Haytni.Plugin
  def on_registration(multi = %Ecto.Multi{}, _module, _config) do
    add_connection_to_multi(multi, conn, user)
  end
end

  @impl Haytni.Plugin
  def on_successful_authentication(conn = %Plug.Conn{}, user = %_{}, multi = %Ecto.Multi{}, keywords, _module, _config) do
    changes =
      keywords
      |> Keyword.put(:current_sign_in_at, Haytni.Helpers.now())
      |> Keyword.put(:last_sign_in_at, user.current_sign_in_at)

    {conn, add_connection_to_multi(multi, conn, user), changes}
  end

  @impl Haytni.Plugin
  def on_delete_user(multi = %Ecto.Multi{}, user = %_{}, _module, %__MODULE__{on_delete: :soft_cascade}) do
    multi
    |> Ecto.Multi.delete_all(:delete_connections, Haytni.TrackablePlugin.QueryHelpers.connections_from_user(user))
  end

  def on_delete_user(multi = %Ecto.Multi{}, _user, _module, _config), do: multi

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
    Returns a queryable for all connections

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
