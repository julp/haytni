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
  def files_to_install do
    import Mix.Tasks.Haytni.Install, only: [web_path: 0, timestamp: 0]
    [
      # migration
      {:eex, "migrations/0-trackable_changes.ex", Path.join([web_path(), "..", "..", "priv", "repo", "migrations", "#{timestamp()}_haytni_trackable_changes.ex"])}, # TODO: less "hacky"
    ]
  end

  @impl Haytni.Plugin
  def fields(module) do
    ip_type = case module.repo().__adapter__() do
      Ecto.Adapters.Postgres ->
        EctoNetwork.INET
      _ ->
        :string
    end

    scope = module.scope()
    quote bind_quoted: [ip_type: ip_type, scope: scope] do
      connection_module = __MODULE__
      |> Module.split()
      |> List.update_at(-1, &(&1 <> "Connection"))
      |> Module.concat()

      contents = quote do
        use Ecto.Schema
        import Ecto.Changeset

        schema "#{unquote(scope)}_connections" do
          field :ip, unquote(ip_type)
          timestamps(updated_at: false)

          belongs_to unquote(String.to_atom(Phoenix.Naming.resource_name(__MODULE__))), unquote(__MODULE__)
        end

        @attributes ~W[ip]a
        def changeset(struct = %__MODULE__{}, params \\ %{}) do
          struct
          |> cast(params, @attributes)
          |> validate_required(@attributes)
        end
      end

      Module.create(connection_module, contents, Macro.Env.location(__ENV__))

      field :last_sign_in_at, :utc_datetime
      field :current_sign_in_at, :utc_datetime

      has_many :connections, connection_module
    end
  end

  @impl Haytni.Plugin
  def on_successful_authentication(conn = %Plug.Conn{}, user = %_{}, multi = %Ecto.Multi{}, keywords, _config) do
    changes = keywords
    |> Keyword.put(:current_sign_in_at, Haytni.Helpers.now())
    |> Keyword.put(:last_sign_in_at, user.current_sign_in_at)

    # user.__struct__.__schema__(:association, :connections).related
    connection = Ecto.build_assoc(user, :connections)
    connection = connection.__struct__.changeset(connection, %{ip: to_string(:inet_parse.ntoa(conn.remote_ip))})

    {conn, Ecto.Multi.insert(multi, :connection, connection), changes}
  end
end
