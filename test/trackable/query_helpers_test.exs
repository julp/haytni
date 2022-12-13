defmodule Haytni.Trackable.QueryHelpersTest do
  use Haytni.DataCase, [
    async: true,
    plugin: Haytni.TrackablePlugin,
  ]
  import Haytni.TrackablePlugin.QueryHelpers

  @base "from u0 in HaytniTest.UserConnection, as: :connections"
  setup do
    [
      user: %HaytniTest.User{id: 78},
    ]
  end

  # borrowed to ecto
  defp i(query) do
    assert "#Ecto.Query<" <> rest = inspect query
    size = byte_size(rest)
    assert ">" = :binary.part(rest, size - 1, 1)
    :binary.part(rest, 0, size - 1)
  end

  test "connections_from_all/1", %{user: user} do
    user
    |> connections_from_all()
    |> i()
    |> (& assert &1 == @base).()
  end

  test "connections_from_user/1", %{user: user} do
    user
    |> connections_from_user()
    |> i()
    |> (& assert &1 == "#{@base}, where: u0.user_id == ^78").()
  end

  test "and_where_ip_equals/2", %{user: user} do
    user
    |> connections_from_all()
    |> and_where_ip_equals("1.2.3.4")
    |> i()
    |> (& assert &1 == "#{@base}, where: u0.ip == ^\"1.2.3.4\"").()

    user
    |> connections_from_user()
    |> and_where_ip_equals("::1")
    |> i()
    |> (& assert &1 == "#{@base}, where: u0.user_id == ^78, where: u0.ip == ^\"::1\"").()
  end

  defp between_date(date), do: between_date(date, date)

  defp between_date(first = %Date{}, last = %Date{}) do
    "where: fragment(\"DATE(?)\", u0.inserted_at) >= type(^#{inspect(first)}, :date), where: fragment(\"DATE(?)\", u0.inserted_at) <= type(^#{inspect(last)}, :date)"
  end

  defp between_date(first, last) do
    "where: u0.inserted_at >= type(^#{inspect(first)}, :date), where: u0.inserted_at <= type(^#{inspect(last)}, :date)"
  end

  test "and_where_date_equals/2", %{user: user} do
    date = ~D[2017-02-23]
    user
    |> connections_from_all()
    |> and_where_date_equals(date)
    |> i()
    |> (& assert &1 == "#{@base}, #{between_date(date)}").()

    date = ~U[2019-10-21 12:34:56Z]
    user
    |> connections_from_user()
    |> and_where_date_equals(date)
    |> i()
    |> (& assert &1 == "#{@base}, where: u0.user_id == ^78, #{between_date(date)}").()
  end

  test "and_where_date_between/3", %{user: user} do
    first = ~U[2011-09-06 17:07:30Z]
    last = ~U[2017-05-30 22:46:56Z]
    user
    |> connections_from_all()
    |> and_where_date_between(first, last)
    |> i()
    |> (& assert &1 == "#{@base}, #{between_date(first, last)}").()

    first = ~D[2018-07-14]
    last = ~D[2015-01-05]
    user
    |> connections_from_user()
    |> and_where_date_between(first, last)
    |> i()
    |> (& assert &1 == "#{@base}, where: u0.user_id == ^78, #{between_date(first, last)}").()
  end
end
