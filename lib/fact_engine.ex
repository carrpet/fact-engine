defmodule Command do
  defstruct [:command, :fact, :arity, :args]
end

defmodule Response do
  defstruct [:queryResponse, :matches]
end


defmodule Reader do
  def len([]), do: 0
  
  def len([h | t]), do: 1 + len(t)

  def parse_args(args) do
    regExp = ~r{[[:alnum:] | [:space:] | ,]+}
    argList = Regex.run(regExp,args)
    [h | _ ] = argList
    parsedArgs = h \
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    %{ :arity => len(parsedArgs), :args => parsedArgs }
  end

  def parse_line(line) do
    [cmd | t] = String.split(line, " ", parts: 3)
    [fact | [args]] = t
    argsData = parse_args(args)
    #lineData = %Command{:command => cmd, :fact => fact}
    #%Command{lineData | argsData }
    %Command{:command => cmd, :fact => fact, :arity => argsData[:arity], :args => argsData[:args]}
  end

  def stream_file(fname) do
    contents = File.stream!(fname)
    contents \
    |> Enum.map(&parse_line/1)
  end

 
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

  def file_transform(fname) do
    fileCmds = Reader.stream_file(fname)
    factMap = Map.put_new(%{}, :responses, [])
    Enum.reduce(fileCmds, factMap, &eval_facts/2)
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
    result = query_helper(args, subjectMap)
    #result = Enum.reduce_while(args,subjects,&lookup_key/2)
    %{responses: respList} = factMap
    %{factMap | responses: respList ++ result}
  end

  def query_helper([h | []], subjectMap) do
    result = subjectMap[h]
    if result == nil, do: [false], else: [result]
  end

  def lookup_key(key, subjectMap) do
    if subjectMap[key] == nil, do: {:halt, false}, else: {:cont, subjectMap[key]}
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
