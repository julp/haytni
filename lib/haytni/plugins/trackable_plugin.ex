defmodule Haytni.TrackablePlugin do
  @moduledoc ~S"""
  TODO
  """

  use Haytni.Plugin

  @impl Haytni.Plugin
  def files_to_install do
    import Mix.Tasks.Haytni.Install, only: [web_path: 0, timestamp: 0]
    [
      # migration
      {:eex, "migrations/trackable_changes.ex", Path.join([web_path(), "..", "..", "priv", "repo", "migrations", "#{timestamp()}_haytni_trackable_changes.ex"])} # TODO: less "hacky"
    ]
  end

  @impl Haytni.Plugin
  def fields do
    quote do
      field :last_sign_in_at, :utc_datetime
      field :current_sign_in_at, :utc_datetime

      has_many :connections, Haytni.Connection
    end
  end


  @impl Haytni.Plugin
  def on_successful_authentification(conn = %Plug.Conn{}, user = %_{}, keywords) do
    changes = keywords
    |> Keyword.put(:current_sign_in_at, Haytni.now())
    |> Keyword.put(:last_sign_in_at, user.current_sign_in_at)

    #%Haytni.Connection{user_id: user.id}
    user
    |> Ecto.build_assoc(:connections)
    |> Haytni.Connection.changeset(%{ip: to_string(:inet_parse.ntoa(conn.remote_ip))})
    |> Haytni.repo().insert!()

    {conn, user, changes}
  end
end
