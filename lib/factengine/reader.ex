defmodule FactEngine.Reader do
  def len([]), do: 0
  
  def len([h | t]), do: 1 + len(t)

  def parse_args(args) do
    regExp = ~r{[[:alnum:] | [:space:] | ,]+}
    argList = Regex.run(regExp,args)
    [h | _ ] = argList
    parsedArgs = h \
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&transform_var/1)
    %{ :arity => len(parsedArgs), :args => parsedArgs }
  end

  def parse_line(line) do
    [cmd | t] = String.split(line, " ", parts: 3)
    [fact | argsList] = t
    [args | _ ] = argsList
    argsData = parse_args(args)
    %Command{:command => cmd, :fact => fact, :arity => argsData[:arity], :args => argsData[:args]}
  end

  def read_file(fname) do
    contents = File.read!(fname)
    contents \
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_line/1)
  end

  def transform_var(argStr) do
    oneCapChar = ~r/^[A-Z]{1}$/
    result = Regex.run(oneCapChar, argStr)
    if result == nil, do: argStr, else: %Variable{ var: List.first(result) }
  end


 
end

