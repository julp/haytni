if false do
  defmodule HaytniTest.Migrations do
    require EEx
    use Ecto.Migration

    @path "#{__DIR__}/../../priv/migrations/"
    @content @path
    |> File.ls!()
    |> Enum.reduce(
      [],
      fn file, acc ->
        File.stream!("#{@path}/#{file}")
        |> Stream.drop(4)
        |> Stream.drop(-2)
        |> Enum.to_list()
        |> Kernel.++(acc)
      end
    )
    |> Enum.join()
    |> EEx.eval_string(table: Haytni.schema().__schema__(:source))
    |> IO.puts()

    def change do
      quote do
        unquote(@content)
      end
    end
  end
end
