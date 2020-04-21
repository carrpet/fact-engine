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

  test "query non existing relation returns false" do
    c1 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["peter"]}
    c2 = %Command{:command => "QUERY", :fact => "is_a_cat", :arity => 1, :args => ["john"]}
    factMap = Map.put_new(%{},:responses, [])
    result = FactEngine.eval_facts(c1, factMap)
    result = FactEngine.eval_facts(c2, result)
    assert %{responses: [false]} = result 
  end

  test "multiple query responses" do
    c1 = %Command{:command => "INPUT", :fact => "are_friends", :arity => 2, :args => ["peter", "john"]}
    c2 = %Command{:command => "QUERY", :fact => "are_friends", :arity => 2, :args => ["peter","john" ]}
    c3 = %Command{:command => "QUERY", :fact => "are_friends", :arity => 2, :args => ["mike","tim"]}
    c4 = %Command{:command => "QUERY", :fact => "are_friends", :arity => 2, :args => ["john","peter"]}
    factMap = Map.put_new(%{},:responses, [])
    result = FactEngine.eval_facts(c1, factMap)
    result = FactEngine.eval_facts(c2, result)
    result = FactEngine.eval_facts(c3, result)
    result = FactEngine.eval_facts(c4, result)
    assert %{responses: [true,false,false]} = result 
   
  end
#
#  test "query multi arity facts" do
#  
#  end
#
end
