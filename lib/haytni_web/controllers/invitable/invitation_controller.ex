defmodule HaytniWeb.Invitable.InvitationController do
  @moduledoc false

  use HaytniWeb, :controller
  use HaytniWeb.Helpers, {Haytni.InvitablePlugin, :with_current_user}
  import Haytni.Gettext

  @spec invitation_sent_message() :: String.t
  def invitation_sent_message do
    dgettext("haytni", "An invitation has been successfully sent")
  end

  defp render_new(conn, changeset = %Ecto.Changeset{}) do
    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  # GET /invitations/new
  # Request a new invitation to be sent to the given email address
  def new(conn, _params, current_user, _module, config)
    when not is_nil(current_user)
  do
    changeset = current_user
    |> Haytni.InvitablePlugin.build_and_assoc_invitation()
    |> Haytni.InvitablePlugin.invitation_to_changeset(config)
    conn
    |> render_new(changeset)
  end

  # POST /invitations
  # Generate and send the invitation
  def create(conn, %{"invitation" => invitation_params}, current_user, module, config)
    when not is_nil(current_user)
  do
    case Haytni.InvitablePlugin.send_invitation(module, config, invitation_params, current_user) do
      {:ok, _invitation} ->
        conn
        |> put_flash(:info, invitation_sent_message())
        |> redirect(to: HaytniWeb.Shared.haytni_path(conn, module, &(:"haytni_#{&1}_invitation_path"), :new))
        |> halt()
      {:error, changeset = %Ecto.Changeset{}} ->
        render_new(conn, changeset)
    end
  end
end
