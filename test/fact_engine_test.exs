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


  ## main query processing routine tests
  test "process_arg 2 variables" do
    table = %{"lia" => %{"sam" => true, "frank" => true},
    "coo" => %{"lia" => true}, "bill" => %{"sam" => true, "john" => true}}
    
    result = Enum.map(Map.keys(table), 
    fn x -> FactEngine.process_arg(x,[%Variable{var: "X"}, %Variable{var: "Y"}], table, %{}) end)
    result = List.flatten(result)
    result = FactEngine.reduce_results(result)
    expected = Enum.reverse([%{"X" => "lia", "Y" => "sam"},
     %{"X" => "lia", "Y" => "frank"},
     %{"X" => "coo", "Y" => "lia"},
     %{"X" => "bill", "Y" => "sam"},
     %{"X" => "bill", "Y" => "john"}])
     assert expected = result
  end

  test "process_arg 1 var and 1 existing" do
    table = %{"lia" => %{"sam" => true, "frank" => true, "lia" => true},
    "coo" => %{"lia" => true}, "bill" => %{"sam" => true, "john" => true}}
    
    result = Enum.map(Map.keys(table), 
    fn x -> FactEngine.process_arg(x,[%Variable{var: "X"}, "sam"], table, %{}) end)
    result = List.flatten(result)
    result = FactEngine.reduce_results(result)
    assert [%{"X" => "bill"}, %{"X" => "lia"}] = result 
  end

  test "process_arg one existing value in the middle of two vars" do
    table = %{"3" => %{"4" => %{"5" => true}, "10" => %{"6" => true}}, 
    "5" => %{"12" => %{"13" => true}}}

    result = Enum.map(Map.keys(table), 
    fn x -> FactEngine.process_arg(x,[%Variable{var: "X"}, "4", %Variable{var: "Y"}], table, %{}) end)

    result = List.flatten(result)
    result = FactEngine.reduce_results(result)
    assert [%{"X" => "3", "Y" => "5"}] = result
  end

  test "process_arg existing values" do
    table = %{"lia" => %{"sam" => true, "frank" => true, "lia" => true},
    "coo" => %{"lia" => true}, "bill" => %{"sam" => true, "john" => true}}

    result = Enum.map(Map.keys(table), 
    fn x -> FactEngine.process_arg(x,["coo", "lia"], table, %{}) end)
    result = List.flatten(result)
    result = FactEngine.reduce_results(result)
    assert result == true
  end

  test "process_arg non-existing values" do
    table = %{"lia" => %{"sam" => true, "frank" => true, "lia" => true},
    "coo" => %{"lia" => true}, "bill" => %{"sam" => true, "john" => true}}

    result = Enum.map(Map.keys(table), 
    fn x -> FactEngine.process_arg(x,["lia", "bill"], table, %{}) end)
    result = List.flatten(result)
    result = FactEngine.reduce_results(result)
    assert result == false
  end

 # test "process_arg same vars" do
 #   table = %{"lia" => %{"sam" => true, "frank" => true, "lia" => true},
 #   "coo" => %{"lia" => true}, "bill" => %{"sam" => true, "john" => true}}
#
 #   result = Enum.map(Map.keys(table), 
 #   fn x -> FactEngine.process_arg(x,[%Variable{var: "X"}, %Variable{var: "X"}], table, %{}) end)
 #   result = List.flatten(result)
 #   result = FactEngine.reduce_results(result)
 #   assert [%{"X" => "lia"}] = result
#
#  end

  test "reduce result with all boolean returns boolean" do
    result = FactEngine.reduce_results([true, false, false, false])
    assert result == true
  end

  test "reduce result, booleans and maps returns maps" do
    result = FactEngine.reduce_results([true,%{:a => "b"}, %{:b => "c"}, false])
    assert [%{a: "b"}, %{b: "c"}] = result
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
