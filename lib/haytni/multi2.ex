if false do
# based on Ecto 3.5.5
defmodule Ecto.Multi2 do
  # <julp>
  #alias __MODULE__
  # </julp>
  alias Ecto.Changeset

  defstruct operations: [], names: MapSet.new()

  @type changes :: map
  @type run :: ((Ecto.Repo.t, changes) -> {:ok | :error, any}) | {module, atom, [any]}
  @type fun(result) :: (changes -> result)
  @type merge :: (changes -> t) | {module, atom, [any]}
  @typep schema_or_source :: binary | {binary | nil, binary} | atom
  @typep operation :: {:changeset, Changeset.t, Keyword.t} |
                      {:run, run} |
                      {:merge, merge} |
                      {:update_all, Ecto.Query.t, Keyword.t} |
                      {:delete_all, Ecto.Query.t, Keyword.t} |
                      # <julp>
                      {:assign, term} |
                      {:one, Ecto.Query.t, Keyword.t} |
                      {:get_by, Ecto.Query.t, Keyword.t | map, Keyword.t} |
                      # </julp>
                      {:insert_all, schema_or_source, [map | Keyword.t], Keyword.t}
  @typep operations :: [{name, operation}]
  @typep names :: MapSet.t
  @type name :: any
  @type t :: %__MODULE__{operations: operations, names: names}

  @spec new :: t
  def new do
    %__MODULE__{}
  end

  @spec append(t, t) :: t
  def append(lhs, rhs) do
    merge_structs(lhs, rhs, &(&2 ++ &1))
  end

  @spec prepend(t, t) :: t
  def prepend(lhs, rhs) do
    merge_structs(lhs, rhs, &(&1 ++ &2))
  end

  defp merge_structs(%__MODULE__{} = lhs, %__MODULE__{} = rhs, joiner) do
    %{names: lhs_names, operations: lhs_ops} = lhs
    %{names: rhs_names, operations: rhs_ops} = rhs
    case MapSet.intersection(lhs_names, rhs_names) |> MapSet.to_list do
      [] ->
        %__MODULE__{names: MapSet.union(lhs_names, rhs_names),
               operations: joiner.(lhs_ops, rhs_ops)}
      common ->
        raise ArgumentError, """
        error when merging the following #{__MODULE__} structs:

        #{inspect(lhs)}

        #{inspect(rhs)}

        both declared operations: #{inspect(common)}
        """
    end
  end

  @spec merge(t, (changes -> t)) :: t
  def merge(%__MODULE__{} = multi, merge) when is_function(merge, 1) do
    Map.update!(multi, :operations, &[{:merge, {:merge, merge}} | &1])
  end

  @spec merge(t, module, function, args) :: t when function: atom, args: [any]
  def merge(%__MODULE__{} = multi, mod, fun, args)
      when is_atom(mod) and is_atom(fun) and is_list(args) do
    Map.update!(multi, :operations, &[{:merge, {:merge, {mod, fun, args}}} | &1])
  end

  @spec insert(t, name, Changeset.t | Ecto.Schema.t | fun(Changeset.t | Ecto.Schema.t), Keyword.t) :: t
  def insert(multi, name, changeset_or_struct_or_fun, opts \\ [])

  def insert(multi, name, %Changeset{} = changeset, opts) do
    add_changeset(multi, :insert, name, changeset, opts)
  end

  def insert(multi, name, %_{} = struct, opts) do
    insert(multi, name, Changeset.change(struct), opts)
  end

  def insert(multi, name, fun, opts) when is_function(fun, 1) do
    run(multi, name, operation_fun({:insert, fun}, opts))
  end

  @spec update(t, name, Changeset.t | fun(Changeset.t), Keyword.t) :: t
  def update(multi, name, changeset_or_fun, opts \\ [])

  def update(multi, name, %Changeset{} = changeset, opts) do
    add_changeset(multi, :update, name, changeset, opts)
  end

  def update(multi, name, fun, opts) when is_function(fun, 1) do
    run(multi, name, operation_fun({:update, fun}, opts))
  end

  @spec insert_or_update(t, name, Changeset.t | fun(Changeset.t), Keyword.t) :: t
  def insert_or_update(multi, name, changeset_or_fun, opts \\ [])

  def insert_or_update(multi, name, %Changeset{data: %{__meta__: %{state: :loaded}}} = changeset, opts) do
    add_changeset(multi, :update, name, changeset, opts)
  end

  def insert_or_update(multi, name, %Changeset{} = changeset, opts) do
    add_changeset(multi, :insert, name, changeset, opts)
  end

  def insert_or_update(multi, name, fun, opts) when is_function(fun, 1) do
    run(multi, name, operation_fun({:insert_or_update, fun}, opts))
  end

  @spec delete(t, name, Changeset.t | Ecto.Schema.t | fun(Changeset.t | Ecto.Schema.t), Keyword.t) :: t
  def delete(multi, name, changeset_or_struct_fun, opts \\ [])

  def delete(multi, name, %Changeset{} = changeset, opts) do
    add_changeset(multi, :delete, name, changeset, opts)
  end

  def delete(multi, name, %_{} = struct, opts) do
    delete(multi, name, Changeset.change(struct), opts)
  end

  def delete(multi, name, fun, opts) when is_function(fun, 1) do
    run(multi, name, operation_fun({:delete, fun}, opts))
  end

  defp add_changeset(multi, action, name, changeset, opts) when is_list(opts) do
    add_operation(multi, name, {:changeset, put_action(changeset, action), opts})
  end

  defp put_action(%{action: nil} = changeset, action) do
    %{changeset | action: action}
  end

  defp put_action(%{action: action} = changeset, action) do
    changeset
  end

  defp put_action(%{action: original}, action) do
    raise ArgumentError, "you provided a changeset with an action already set to #{inspect(original)} when trying to #{action} it"
  end

  @spec error(t, name, error :: term) :: t
  def error(multi, name, value) do
    add_operation(multi, name, {:error, value})
  end

  @spec run(t, name, run) :: t
  def run(multi, name, run) when is_function(run, 2) do
    add_operation(multi, name, {:run, run})
  end

  @spec run(t, name, module, function, args) :: t when function: atom, args: [any]
  def run(multi, name, mod, fun, args)
      when is_atom(mod) and is_atom(fun) and is_list(args) do
    add_operation(multi, name, {:run, {mod, fun, args}})
  end

  @spec insert_all(t, name, schema_or_source, [map | Keyword.t] | fun([map | Keyword.t]), Keyword.t) :: t
  def insert_all(multi, name, schema_or_source, entries_or_fun, opts \\ [])

  def insert_all(multi, name, schema_or_source, entries_fun, opts) when is_function(entries_fun, 1) and is_list(opts) do
    run(multi, name, operation_fun({:insert_all, schema_or_source, entries_fun}, opts))
  end

  def insert_all(multi, name, schema_or_source, entries, opts) when is_list(opts) do
    add_operation(multi, name, {:insert_all, schema_or_source, entries, opts})
  end

  @spec update_all(t, name, Ecto.Queryable.t | fun(Ecto.Queryable.t), Keyword.t, Keyword.t) :: t
  def update_all(multi, name, queryable_or_fun, updates, opts \\ [])

  def update_all(multi, name, queryable_fun, updates, opts) when is_function(queryable_fun, 1) and is_list(opts) do
    run(multi, name, operation_fun({:update_all, queryable_fun, updates}, opts))
  end

  def update_all(multi, name, queryable, updates, opts) when is_list(opts) do
    query = Ecto.Queryable.to_query(queryable)
    add_operation(multi, name, {:update_all, query, updates, opts})
  end

  @spec delete_all(t, name, Ecto.Queryable.t | fun(Ecto.Queryable.t), Keyword.t) :: t
  def delete_all(multi, name, queryable_or_fun, opts \\ [])

  def delete_all(multi, name, fun, opts) when is_function(fun, 1) and is_list(opts) do
    run(multi, name, operation_fun({:delete_all, fun}, opts))
  end

  def delete_all(multi, name, queryable, opts) when is_list(opts) do
    query = Ecto.Queryable.to_query(queryable)
    add_operation(multi, name, {:delete_all, query, opts})
  end

  # <julp>
  @spec assign(t, name, value :: term) :: t
  def assign(multi, name, value) do
    add_operation(multi, name, {:ok, value})
  end

  @spec one(t, name, Ecto.Queryable.t | fun(Ecto.Queryable.t), Keyword.t) :: t
  def one(multi, name, queryable_or_fun, opts \\ [])

  def one(multi, name, fun, opts) when is_function(fun, 1) and is_list(opts) do
    run(multi, name, operation_fun({:one, fun}, opts))
  end

  def one(multi, name, queryable, opts) when is_list(opts) do
    query = Ecto.Queryable.to_query(queryable)
    add_operation(multi, name, {:one, query, opts})
  end

  @typep clauses :: Keyword.t | map
  @spec get_by(t, name, Ecto.Queryable.t, clauses | fun(clauses), Keyword.t) :: t
  def get_by(multi, name, queryable, clauses_or_fun, opts \\ [])

  #def get_by(multi, name, queryable, fun, opts) when is_function(fun, 1) and is_list(opts) do
    #run(multi, name, operation_fun({:one, fun}, opts))
  #end

  def get_by(multi, name, queryable, clauses, opts) when is_list(opts) do
    require Ecto.Query

    query = Ecto.Query.where(queryable, [], ^Enum.to_list(clauses))
    add_operation(multi, name, {:one, query, opts})
  end

  @spec apply_action(t, name, Ecto.Changeset.t, atom) :: t
  def apply_action(multi, name, changeset, action \\ :insert) do
    tuple =
      changeset
      |> Ecto.Changeset.apply_action(action)
    add_operation(multi, name, tuple)
  end
  # </julp>

  defp add_operation(%__MODULE__{} = multi, name, operation) do
    %{operations: operations, names: names} = multi
    if MapSet.member?(names, name) do
      raise "#{inspect name} is already a member of the #{__MODULE__}: \n#{inspect multi}"
    else
      %{multi | operations: [{name, operation} | operations], names: MapSet.put(names, name)}
    end
  end

  @spec to_list(t) :: [{name, term}]
  def to_list(%__MODULE__{operations: operations}) do
    operations
    |> Enum.reverse
    |> Enum.map(&format_operation/1)
  end

  defp format_operation({name, {:changeset, changeset, opts}}),
    do: {name, {changeset.action, changeset, opts}}
  defp format_operation(other),
    do: other

  @doc false
  @spec __apply__(t, Ecto.Repo.t, fun, (term -> no_return)) :: {:ok, term} | {:error, term}
  # JULP: def => defp (does not need to be public since transaction/4 was moved from Ecto.Repo.Transaction)
  defp __apply__(%__MODULE__{} = multi, repo, wrap, return) do
    operations = Enum.reverse(multi.operations)

    with {:ok, operations} <- check_operations_valid(operations) do
      apply_operations(operations, multi.names, repo, wrap, return)
    end
  end

  # <julp>
  # JULP: imported and adapted from Ecto.Repo.Transaction
  def transaction(%__MODULE__{} = multi, repo, opts \\ []) do
    name = repo.get_dynamic_repo()
    {adapter, meta} = Ecto.Repo.Registry.lookup(name)
    wrap = &adapter.transaction(meta, opts, &1)
    return = &adapter.rollback(meta, &1)

    # JULP: Ecto.Multi.__apply__ => __apply__ (function moved from Ecto.Repo.Transaction)
    case __apply__(multi, repo, wrap, return) do
      {:ok, values} -> {:ok, values}
      {:error, {key, error_value, values}} -> {:error, key, error_value, values}
      {:error, operation} -> raise "operation #{inspect operation} is manually rolling back, which is not supported by #{__MODULE__}"
    end
  end
  # </julp>

  defp check_operations_valid(operations) do
    Enum.find_value(operations, &invalid_operation/1) || {:ok, operations}
  end

  defp invalid_operation({name, {:changeset, %{valid?: false} = changeset, _}}),
    do: {:error, {name, changeset, %{}}}
  defp invalid_operation({name, {:error, value}}),
    do: {:error, {name, value, %{}}}
  defp invalid_operation(_operation),
    do: nil

  defp apply_operations([], _names, _repo, _wrap, _return), do: {:ok, %{}}
  defp apply_operations(operations, names, repo, wrap, return) do
    wrap.(fn ->
      operations
      # <julp>
      #|> Enum.reduce({%{}, names}, &apply_operation(&1, repo, wrap, return, &2))
      |> Enum.reduce_while({%{}, names}, &apply_operation(&1, repo, wrap, return, &2))
      # </julp>
      |> elem(0)
    end)
  end

  defp apply_operation({_, {:merge, merge}}, repo, wrap, return, {acc, names}) do
    case __apply__(apply_merge_fun(merge, acc), repo, wrap, return) do
      {:ok, value} ->
        merge_results(acc, value, names)
      {:error, {name, value, nested_acc}} ->
        {acc, _names} = merge_results(acc, nested_acc, names)
        return.({name, value, acc})
    end
  end

  defp apply_operation({name, operation}, repo, wrap, return, {acc, names}) do
    case apply_operation(operation, acc, {wrap, return}, repo) do
      {:ok, value} ->
      # <julp>
        #{Map.put(acc, name, value), names}
        {:cont, {Map.put(acc, name, value), names}}
      {:stop, value} ->
        {:halt, {Map.put(acc, name, value), names}}
      # </julp>
      {:error, value} ->
        return.({name, value, acc})
      other ->
        raise "expected #{__MODULE__} callback named `#{inspect(name)}` to return either {:ok, value} or {:error, value}, got: #{inspect(other)}"
    end
  end

  defp apply_operation({:changeset, changeset, opts}, _acc, _apply_args, repo),
    do: apply(repo, changeset.action, [changeset, opts])
  defp apply_operation({:run, run}, acc, _apply_args, repo),
    do: apply_run_fun(run, repo, acc)
  defp apply_operation({:error, value}, _acc, _apply_args, _repo),
    do: {:error, value}
  defp apply_operation({:insert_all, source, entries, opts}, _acc, _apply_args, repo),
    do: {:ok, repo.insert_all(source, entries, opts)}
  defp apply_operation({:update_all, query, updates, opts}, _acc, _apply_args, repo),
    do: {:ok, repo.update_all(query, updates, opts)}
  defp apply_operation({:delete_all, query, opts}, _acc, _apply_args, repo),
    do: {:ok, repo.delete_all(query, opts)}
  # <julp>
  # used by assign/3 and apply/3
  defp apply_operation({:ok, value}, _acc, _apply_args, _repo),
    do: {:ok, value}
  defp apply_operation({:one, query, opts}, _acc, _apply_args, repo) do
    query
    |> repo.one(opts)
    |> stop_on_nil()
  end

  #defp apply_operation({:get_by, query, opts}, _acc, _apply_args, repo) do
    #query
    #|> repo.get_by(opts)
    #|> stop_on_nil()
  #end

  defp stop_on_nil(nil), do: {:stop, nil}
  defp stop_on_nil(other), do: {:ok, other}
  # </julp>

  defp apply_merge_fun({mod, fun, args}, acc), do: apply(mod, fun, [acc | args])
  defp apply_merge_fun(fun, acc), do: apply(fun, [acc])

  defp apply_run_fun({mod, fun, args}, repo, acc), do: apply(mod, fun, [repo, acc | args])
  defp apply_run_fun(fun, repo, acc), do: apply(fun, [repo, acc])

  defp merge_results(changes, new_changes, names) do
    new_names = new_changes |> Map.keys |> MapSet.new()
    case MapSet.intersection(names, new_names) |> MapSet.to_list do
      [] ->
        {Map.merge(changes, new_changes), MapSet.union(names, new_names)}
      common ->
        raise "cannot merge multi, the following operations were found in both #{__MODULE__}: #{inspect(common)}"
    end
  end

  defp operation_fun({:update_all, queryable_fun, updates}, opts) do
    fn repo, changes ->
      {:ok, repo.update_all(queryable_fun.(changes), updates, opts)}
    end
  end

  defp operation_fun({:insert_all, schema_or_source, entries_fun}, opts) do
    fn repo, changes ->
      {:ok, repo.insert_all(schema_or_source, entries_fun.(changes), opts)}
    end
  end

  defp operation_fun({:delete_all, fun}, opts) do
    fn repo, changes ->
      {:ok, repo.delete_all(fun.(changes), opts)}
    end
  end

  # <julp>
  defp operation_fun({:one, fun}, opts) do
    fn repo, changes ->
      changes
      |> fun.()
      |> case do
        nil ->
          {:stop, nil}
        queryable ->
          queryable
          |> repo.one(opts)
          |> stop_on_nil()
      end
    end
  end
  # </julp>

  defp operation_fun({operation, fun}, opts) do
    fn repo, changes ->
      apply(repo, operation, [fun.(changes), opts])
    end
  end
end
end # if false do
