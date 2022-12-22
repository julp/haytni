defmodule Haytni.Trackable.OnDeleteTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.TrackablePlugin,
  ]

  alias HaytniTest.User

  describe "Haytni.TrackablePlugin.on_delete_user/4 (callback)" do
    setup do
      user = user_fixture()
      connection = connection_fixture(@repo, user)

      binding()
    end

    test "ensures connections are not deleted when config.on_delete is nil", %{user: user = %User{id: id}} do
      config = @plugin.build_config(on_delete: nil)
      multi = @plugin.on_delete_user(Ecto.Multi.new(), user, @stack, config)

      assert [] = Ecto.Multi.to_list(multi)

      @repo.transaction(multi)
      assert [%HaytniTest.UserConnection{user_id: ^id}] = list_connections(@repo, user)
    end

    test "ensures connections are deleted when config.on_delete is :soft_cascade", %{user: user} do
      config = @plugin.build_config(on_delete: :soft_cascade)
      multi = @plugin.on_delete_user(Ecto.Multi.new(), user, @stack, config)

      assert [{:delete_connections, {:delete_all, %Ecto.Query{}, []}}] = Ecto.Multi.to_list(multi)

      @repo.transaction(multi)
      assert [] = list_connections(@repo, user)
    end
  end
end
