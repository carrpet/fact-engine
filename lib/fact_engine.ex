defmodule Command do
  defstruct [:command, :fact, :arity, :args]
end

defmodule Response do
  defstruct [:queryResponse, :matches]
end




defmodule FactEngine do
  @moduledoc """
  Documentation for `FactEngine`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> FactEngine.hello()
      :world

  """
  defstruct [:responses]
  def hello do
    :world
  end

  def eval_file(lines) do
    factMap = Map.put_new(%{}, :responses, [])
    Enum.reduce(lines, factMap, &eval_facts/2)
  end

  def eval_facts(cmd, factMap) do
    funcMap = %{"INPUT" => &input/4, "QUERY" => &query/4}
    %Command{command: a, fact: b, arity: c, args: d} = cmd
    funcMap[a].(b,c,d, factMap)
  end

  def input(fact, arity, args, factMap) do

    if factMap[fact] == nil do
      add_fact(fact, arity, args, factMap)
    else
      update_fact(fact,arity,args,factMap)
    end

  end

  def query(fact, arity, args, factMap) do
    %{^arity => subjectMap } = factMap[fact]
    result = Enum.reduce_while(args,subjectMap,&lookup_key/2)
    %{responses: respList} = factMap
    %{factMap | responses: respList ++ [result]}
  end

  def lookup_key(key, subjectMap) do
    if subjectMap[key] == nil, do: {:halt,false}, else: {:cont, subjectMap[key]}
  end

  def add_fact(fact, arity, args, factMap) do
    keyToAdd = setup_dict(%{},Enum.reverse(args))
    Map.put_new(factMap, fact, %{ arity => keyToAdd })
  end

  def setup_dict(dict,[]), do: dict

  def setup_dict(dict,items) do
    [h | t] = items
    key = List.first(Map.keys(dict))
    if key == nil do
      setup_dict(Map.put_new(dict,h,true),t)
    else
      added = Map.put_new(dict,h,%{key => dict[key]})
      Map.delete(added,key) 
      setup_dict(Map.delete(added,key),t)
    end
  end


  def update_fact(key, arity, args, factMap) do
    %{^arity => oldDict} = factMap[key]
    newDict = update_dict(args,oldDict)
    %{factMap | key => %{arity => newDict}}
  end

  def update_dict([h | []], dict) do
    Map.put_new(dict,h,true)
  end


  defmodule Writer do


  end
  
end
