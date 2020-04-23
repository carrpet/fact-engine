defmodule Command do
  defstruct [:command, :fact, :arity, :args]
end

defmodule Variable do
  defstruct [:var]
end

defmodule FactEngine do
  def dispatch_cmd(%Command{command: "INPUT", fact: fact, arity: arity, args: args}, factMap) do
    {FactEngine.eval_input(fact, arity, args, factMap), :input}
  end

  def dispatch_cmd(%Command{command: "QUERY", fact: fact, arity: arity, args: args}, factMap) do
    {FactEngine.eval_query(fact, arity, args, factMap), :query}
  end

  def eval_file([h | []], factMap, responses) do
    {result, type} = dispatch_cmd(h, factMap)
    if type == :query, do: responses ++ result, else: responses
  end

  def eval_file([h | t], factMap, responses) do
    {result, type} = dispatch_cmd(h, factMap)

    if type == :input,
      do: eval_file(t, result, responses),
      else: eval_file(t, factMap, responses ++ result)
  end

  def eval_input(fact, arity, args, factMap) do
    if factMap[fact] == nil do
      add_fact(fact, arity, args, factMap)
    else
      update_fact(fact, arity, args, factMap)
    end
  end

  def eval_query(fact, arity, args, factMap) do
    if factMap[fact] == nil do
      [false]
    else
      %{^arity => subjectMap} = factMap[fact]
      keys = Map.keys(subjectMap)

      keys
      |> Enum.map(fn x -> process_arg(x, args, subjectMap, %{}) end)
      |> List.flatten()
      |> reduce_results
    end
  end

  def process_arg(key, [%Variable{var: h} | []], _table, acc) do
    sameVar = fn
      %{^h => ^key} -> acc
      %{^h => _} -> []
      _ -> Map.put_new(acc, h, key)
    end

    sameVar.(acc)
  end

  def process_arg(key, [%Variable{var: h} | t], table, acc) do
    sameVar = fn
      %{^h => ^key} ->
        nextKeys = Map.keys(table[key])
        Enum.map(nextKeys, fn x -> process_arg(x, t, table[key], acc) end)

      %{^h => _} ->
        []

      _ ->
        newAcc = Map.put_new(acc, h, key)
        nextKeys = Map.keys(table[key])
        Enum.map(nextKeys, fn x -> process_arg(x, t, table[key], newAcc) end)
    end

    sameVar.(acc)
  end

  def process_arg(key, [h | []], _table, acc) do
    if key == h do
      if Map.equal?(acc, %{}), do: true, else: acc
    else
      false
    end
  end

  def process_arg(key, [h | t], table, acc) do
    nextKeys = Map.keys(table[key])

    if key == h,
      do: Enum.map(nextKeys, fn x -> process_arg(x, t, table[key], acc) end),
      else: false
  end

  def add_fact(fact, arity, args, factMap) do
    keyToAdd = setup_dict(%{}, Enum.reverse(args))
    Map.put_new(factMap, fact, %{arity => keyToAdd})
  end

  def setup_dict(dict, []), do: dict

  def setup_dict(dict, items) do
    [h | t] = items
    key = List.first(Map.keys(dict))

    if key == nil do
      setup_dict(Map.put_new(dict, h, true), t)
    else
      added = Map.put_new(dict, h, %{key => dict[key]})
      Map.delete(added, key)
      setup_dict(Map.delete(added, key), t)
    end
  end

  def update_fact(key, arity, args, factMap) do
    %{^arity => oldDict} = factMap[key]
    newDict = update_dict(args, oldDict)
    Map.replace!(factMap, key, %{arity => newDict})
  end

  def update_dict([h | []], dict) do
    Map.put_new(dict, h, true)
  end

  def update_dict([h | t], table) do
    if table[h] != nil,
      do: %{h => update_dict(t, table[h])},
      else: Map.put_new(table, h, setup_dict(%{}, t))
  end

  def update_dict(args, nil) do
    setup_dict(%{}, Enum.reverse(args))
  end

  def reduce_results([]) do
    [false]
  end

  def reduce_results(results) do
    selectMaps = fn
      x when not is_boolean(x) -> true
      _ -> false
    end

    mapItems = Enum.filter(results, selectMaps)

    f = fn
      [] -> [Enum.reduce(results, fn x, acc -> x or acc end)]
      _ -> Enum.reverse(mapItems)
    end

    f.(mapItems)
  end
end
