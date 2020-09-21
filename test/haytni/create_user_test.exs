defmodule Haytni.CreateUserTest do
  use HaytniWeb.ConnCase, async: true

  describe "Haytni.create_user/3" do
    test "successful with valid data" do
      params =
        [
          email: "test@test.com",
          password: "0123456789-abcdef-ABCDEF",
        ]
        |> Params.create()
        |> Params.confirm(~W[email password]a)

      assert {:ok, %{user: %HaytniTest.User{}}} = Haytni.create_user(HaytniTestWeb.Haytni, params)
    end

    test "fails if password is too short" do
      params =
        [
          email: "test@test.com",
          password: "123",
        ]
        |> Params.create()
        |> Params.confirm(~W[email password]a)

      assert {:error, :user, %Ecto.Changeset{errors: [password: {"should be at least %{count} character(s)", _}]}, %{}} = Haytni.create_user(HaytniTestWeb.Haytni, params)
    end
  end
end
