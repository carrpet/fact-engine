defmodule FactEngineTest do
  use ExUnit.Case
  doctest FactEngine

  test "input new fact creates correct map representation" do
    result = FactEngine.eval_facts(%Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["bob"]},%{})
    assert %{"is_a_cat" => %{1 => %{"bob" => true}}} = result
  end


  test "multiple inputs return proper map" do
    c1 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["kcf"]}
    c2 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["fatty"]}
    result = Enum.reduce([c1,c2], %{}, &FactEngine.eval_facts/2)
    assert %{"is_a_cat" => %{ 1 => %{"kcf" => true ,"fatty" => true}}} = result
  end
  
  test "input different arity facts" do
    c1 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["johnny"]}
    c2 = %Command{:command => "INPUT", :fact => "are_friends", :arity => 2, :args => ["sam","peter"]}
    result = Enum.reduce([c1,c2], %{}, &FactEngine.eval_facts/2)
    assert %{"is_a_cat" => %{ 1 => %{"johnny" => true }},
     "are_friends" => %{2 => %{"sam" => %{"peter" => true}}}} = result
  end

  test "query existing 1-rity function arg returns true" do
    c1 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["peter"]}
    c2 = %Command{:command => "QUERY", :fact => "is_a_cat", :arity => 1, :args => ["peter"]}
    factMap = Map.put_new(%{},:responses, [])
    result = Enum.reduce([c1,c2], factMap, &FactEngine.eval_facts/2)
    assert %{responses: [true]} = result
  end

  test "query non existing relation returns false" do
    c1 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["peter"]}
    c2 = %Command{:command => "QUERY", :fact => "is_a_cat", :arity => 1, :args => ["john"]}
    factMap = Map.put_new(%{},:responses, [])
    result = Enum.reduce([c1,c2], factMap, &FactEngine.eval_facts/2)
    assert %{responses: [false]} = result 
  end

  test "multiple query responses" do
    c1 = %Command{:command => "INPUT", :fact => "are_friends", :arity => 2, :args => ["peter", "john"]}
    c2 = %Command{:command => "QUERY", :fact => "are_friends", :arity => 2, :args => ["peter","john" ]}
    c3 = %Command{:command => "QUERY", :fact => "are_friends", :arity => 2, :args => ["mike","tim"]}
    c4 = %Command{:command => "QUERY", :fact => "are_friends", :arity => 2, :args => ["john","peter"]}
    factMap = Map.put_new(%{},:responses, [])
    result = Enum.reduce([c1,c2,c3,c4], factMap, &FactEngine.eval_facts/2)
    assert %{responses: [true,false,false]} = result 
  end

  test "variable 1-arity fact query" do
    c1 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["kcf"]}
    c2 = %Command{:command => "INPUT", :fact => "is_a_dog", :arity => 1, :args => ["lia"]}
    c3 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["chester"]}
    c4 = %Command{:command => "QUERY", :fact => "is_a_cat", :arity => 1, :args => [%Variable{var: "X"}]}
    factMap = Map.put_new(%{},:responses, [])
    result = Enum.reduce([c1,c2,c3,c4], factMap, &FactEngine.eval_facts/2)
    assert %{responses: [%{"X" => ["kcf", "chester"]}]} = result
  end

  test "process_args 2 variables" do
    table = %{"lia" => %{"sam" => true, "frank" => true},
    "coo" => %{"lia" => true}, "bill" => %{"sam" => true, "john" => true}}
    
    result = Enum.map(Map.keys(table), 
    fn x -> FactEngine.process_arg(x,[%Variable{var: "X"}, %Variable{var: "Y"}], table, %{}) end)
   
    expected = Enum.reverse([%{%Variable{var: "X"} => "lia", %Variable{var: "Y"} => "sam"},
     %{%Variable{var: "X"} => "lia", %Variable{var: "Y"} => "frank"},
     %{%Variable{var: "X"} => "coo", %Variable{var: "Y"} => "lia"},
     %{%Variable{var: "X"} => "bill", %Variable{var: "Y"} => "sam"},
     %{%Variable{var: "X"} => "bill", %Variable{var: "Y"} => "john"}])
     assert expected = result
  end

  test "process_args 1 var and 1 existing" do
    table = %{"lia" => %{"sam" => true, "frank" => true, "lia" => true},
    "coo" => %{"lia" => true}, "bill" => %{"sam" => true, "john" => true}}
    
    result = Enum.map(Map.keys(table), 
    fn x -> FactEngine.process_arg(x,[%Variable{var: "X"}, "sam"], table, %{}) end)

    assert [%{%Variable{var: "X"} => "bill"}, %{%Variable{var: "X"} => "lia"}] = result 
  end

 # test "nested variable query" do
 #   c1 = %Command{:command => "INPUT", :fact => "are_friends", :arity => 2, :args => ["peter", "john"]}
 #   c2 = %Command{:command => "INPUT", :fact => "are_friends", :arity => 2, :args => ["peter", "frank"]}
 #   c3 = %Command{:command => "INPUT", :fact => "are_friends", :arity => 2, :args => ["willy", "john"]}
 #   c4 = %Command{:command => "QUERY", :fact => "are_friends", :arity => 2, :args => ["X", "Y"]}
 #   factMap = Map.put_new(%{},:responses, [])
 #   result = Enum.reduce([c1,c2,c3,c4], factMap, &FactEngine.eval_facts/2)
 #   assert %{responses: [%{"X" => ["kcf", "chester"]}]} = result
 
 # end

end
