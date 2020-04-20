defmodule Command do
  defstruct [:command, :fact, :arity, :args]

end

defmodule Reader do
  def len([]), do: 0
  
  def len([h | t]), do: 1 + len(t)

  def parse_args(args) do
    parsedArgs = String.split(args,["(",")"])
    |> Enum.join("")
    |> String.split(",")
    %{ :arity => len(parsedArgs), :args => parsedArgs }
  end

  def parse_line(line) do
    [cmd | t] = String.split(line)
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
  def hello do
    :world
  end

  def file_transform(fname) do
    fileCmds = Reader.stream_file(fname)
    Enum.reduce(fileCmds, %{}, &eval_facts/2)
  end

  def eval_facts(cmd, factMap) do
    funcMap = %{"INPUT" => &input/4, "QUERY" => &query/3}
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

  def query(func, args, queries) do
    :called_query
  end

  def add_fact(fact, arity, args, factMap)  do
    Map.put_new(factMap, fact, %{arity => [args]}) 
  end

  def update_fact(key, arity, args, factMap) do
    %{^arity => oldArgs} = factMap[key]
    %{factMap | arity => oldArgs ++ args }
  end


#  def update_value(factMap,key,args) do
#    funcargs = parse_args(args)
#    {arity, argsList } = funcargs
 #   if factMap[key] == nil do 
 #     Map.put_new(factMap, key, %{arity => [argsList]})
 #   else
 #     %{^arity => oldArgs} = factMap[key]
 #     %{factMap | arity => oldArgs ++ argsList }
 #   end
  #
 # end

  

end
