if false do
# mix test test/multi2_test.exs
defmodule Haytni.Multi2Test do
  use Haytni.DataCase, async: true

  alias HaytniTest.User

  describe "Multi2.one/3" do
    setup do
      marcel = user_fixture(lastname: "Marcel")

      {:ok, user: marcel}
    end

    defp user_from_lastname_query(lastname) do
      import Ecto.Query

      from(HaytniTest.User, where: [lastname: ^lastname])
    end

    defp do_test(lastname) do
      q =
        lastname
        |> user_from_lastname_query()

      Ecto.Multi2.new()
      |> Ecto.Multi2.one(:user, q)
      |> Ecto.Multi2.run(:after, fn _repo, _changes -> {:ok, 0} end)
      |> Ecto.Multi2.transaction(HaytniTest.Repo)
    end

    defp do_test2(lastname) do
      Ecto.Multi2.new()
      |> Ecto.Multi2.one(:user, fn _changes -> lastname |> user_from_lastname_query() end)
      |> Ecto.Multi2.run(:after, fn _repo, _changes -> {:ok, 0} end)
      |> Ecto.Multi2.transaction(HaytniTest.Repo)
    end

    test "one with queryable as argument", %{user: _user} do
      assert {:ok, %{user: %User{}, after: 0}} = do_test("Marcel")
      assert {:ok, %{user: nil}} == do_test("Pierre")
    end

    test "one with a function as argument", %{user: _user} do
      assert {:ok, %{user: %User{}, after: 0}} = do_test2("Marcel")
      assert {:ok, %{user: nil}} == do_test("Pierre")
    end

    test "chaining one/3 with a regular Ecto.Multi function", %{user: user} do
      q =
        user.lastname
        |> user_from_lastname_query()

      Ecto.Multi2.new()
      |> Ecto.Multi2.one(:user, q)
      |> Ecto.Multi2.delete_all(:revoke_tokens, fn %{user: user} -> Haytni.Token.tokens_from_user_query(user, :all) end)
      |> Ecto.Multi2.transaction(HaytniTest.Repo)
      |> (& assert {:ok, %{user: %User{}, revoke_tokens: {0, nil}}} = &1).()
    end
  end

  describe "Multi2.run/3" do
    test "returning {:stop, any} doesn't further execute the multi" do
      for atom <- ~W[stop ok error]a do
        Ecto.Multi2.new()
        |> Ecto.Multi2.run(:a, fn _repo, _changes -> {:stop, 1} end)
        |> Ecto.Multi2.run(:b, fn _repo, _changes -> {atom, 2} end)
        |> Ecto.Multi2.transaction(HaytniTest.Repo)
        |> (& assert {:ok, %{a: 1}} == &1).()
      end
    end

    test "returning {:error, any} still avorts the multi" do
      Ecto.Multi2.new()
      |> Ecto.Multi2.run(:a, fn _repo, _changes -> {:error, 1} end)
      |> Ecto.Multi2.run(:b, fn _repo, _changes -> {:ok, 2} end)
      |> Ecto.Multi2.transaction(HaytniTest.Repo)
      |> (& assert {:error, :a, 1, %{}} == &1).()

      Ecto.Multi2.new()
      |> Ecto.Multi2.run(:a, fn _repo, _changes -> {:ok, 1} end)
      |> Ecto.Multi2.run(:b, fn _repo, _changes -> {:error, 2} end)
      |> Ecto.Multi2.transaction(HaytniTest.Repo)
      |> (& assert {:error, :b, 2, %{a: 1}} == &1).()
    end
  end

  describe "Multi2.assign/3" do
    test "chaining assign/3 with a regular Ecto.Multi function" do
      Ecto.Multi2.new()
      |> Ecto.Multi2.assign(:a, 1)
      |> Ecto.Multi2.run(:b, fn _repo, %{a: a} -> {:ok, a + 1} end)
      |> Ecto.Multi2.transaction(HaytniTest.Repo)
      |> (& assert {:ok, %{a: 1, b: 2}} == &1).()
    end
  end
end
end # if false do
