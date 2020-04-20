defmodule FactEngineTest do
  use ExUnit.Case
  doctest FactEngine

  test "input new fact creates correct map representation" do
    result = FactEngine.eval_facts(%Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["bob"]},%{})
    assert %{"is_a_cat" => %{1 => [["bob"]]}} = result
  end

#  test "input different facts" do
#    result = FactEngine.eval_facts("INPUT is_a_cat (bob)", %{})
#    result = FactEngine.eval_facts("INPUT are_friends (jim,joe)", result)
#    assert %{"is_a_cat" => a, "are_friends" => b} = result
#  end

  test "multiple inputs return proper map" do
    cmd = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["kcf"]}
    cmd2 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["bob"]}
    result = FactEngine.eval_facts(cmd, %{})
    result = FactEngine.eval_facts(cmd2, result)
    assert %{"is_a_cat" => %{1 => [["kcf"],["fatty"]]}} = result
  end

 # test "query existing one argument retrieves" do
 #   result = FactEngine.eval_facts("INPUT is_a_cat (kcf)", %{})
 #   result = FactEngine.eval_facts("QUERY is_a_cat (kcf)", result)
 #   true = result 

end

defmodule ReaderTest do
  use ExUnit.Case
  doctest Reader

  test "read the file" do
    result = Reader.stream_file("in.txt")
    [a, b] = result
    %Command{command: "INPUT", fact: "is_a_cat", arity: 1, args: ["lucy"]} = a
  end
end
