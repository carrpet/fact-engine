defmodule FactEngineTest do
  use ExUnit.Case
  doctest FactEngine

  test "input new fact creates correct map representation" do
    result = FactEngine.eval_facts(%Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["bob"]},%{})
    assert %{"is_a_cat" => %{1 => %{"bob" => true}}} = result
  end


  test "multiple inputs return proper map" do
    cmd = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["kcf"]}
    cmd2 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["fatty"]}
    result = FactEngine.eval_facts(cmd, %{})
    result = FactEngine.eval_facts(cmd2, result)
    assert %{"is_a_cat" => %{ 1 => %{"kcf" => true ,"fatty" => true}}} = result
  end
  
  test "input different arity facts" do
    f1 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["johnny"]}
    f2 = %Command{:command => "INPUT", :fact => "are_friends", :arity => 2, :args => ["sam","peter"]}
    result = FactEngine.eval_facts(f1, %{})
    result = FactEngine.eval_facts(f2, result)
    assert %{"is_a_cat" => %{ 1 => %{"johnny" => true }},
     "are_friends" => %{2 => %{"sam" => %{"peter" => true}}}} = result
  end

  test "query existing 1-rity function arg returns true" do
    f1 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["peter"]}
    f2 = %Command{:command => "QUERY", :fact => "is_a_cat", :arity => 1, :args => ["peter"]}
    factMap = Map.put_new(%{},:responses, [])
    result = FactEngine.eval_facts(f1, factMap)
    result = FactEngine.eval_facts(f2, result)
    assert %{responses: [true]} = result
  end
end

defmodule ReaderTest do
  use ExUnit.Case
  doctest Reader

  test "read the file" do
    result = Reader.stream_file("in.txt")
    [a, _] = result
    %Command{command: "INPUT", fact: "is_a_cat", arity: 1, args: ["lucy"]} = a
  end

  test "parse line returns command one arg" do
    result = Reader.parse_line("INPUT is_a_cat (lucy)")
    %Command{command: "INPUT", fact: "is_a_cat", arity: 1, args: ["lucy"]} = result
  end

  test "parse line returns command multiple args" do
    result = Reader.parse_line("QUERY are_friends (frank, sam)")
    %Command{command: "QUERY", fact: "are_friends", arity: 2} = result
  end
end
