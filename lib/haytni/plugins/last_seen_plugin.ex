defmodule Haytni.LastSeenPlugin do
  @moduledoc """
  This module memorizes when a user lastly signed in

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
      {:eex, "migrations/0-last_seen_changes.exs", Path.join([web_path, "..", "..", "priv", "repo", "migrations", "#{timestamp}_haytni_last_seen_#{scope}_changes.exs"])},
    ]
  end

  @impl Haytni.Plugin
  def fields(module) do
    quote do
      field :last_sign_in_at, :utc_datetime
      field :current_sign_in_at, :utc_datetime
    end
  end

  @impl Haytni.Plugin
  def on_successful_authentication(conn = %Plug.Conn{}, user = %_{}, multi = %Ecto.Multi{}, keywords, _module, _config) do
    changes =
      keywords
      |> Keyword.put(:current_sign_in_at, Haytni.Helpers.now())
      |> Keyword.put(:last_sign_in_at, user.current_sign_in_at)

    {conn, multi, changes}
  end
end
