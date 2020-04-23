defmodule FactEngineTest do
  use ExUnit.Case
  doctest FactEngine

  # eval_input tests

  test "input new fact creates correct map representation" do
    result = FactEngine.eval_input("is_a_cat", 1, ["bob"], %{})
    assert %{"is_a_cat" => %{1 => %{"bob" => true}}} = result
  end

  test "multiple inputs return proper map" do
    r1 = FactEngine.eval_input("is_a_cat", 1, ["kcf"], %{})
    r2 = FactEngine.eval_input("is_a_cat", 1, ["fatty"], r1)
    assert %{"is_a_cat" => %{1 => %{"kcf" => true, "fatty" => true}}} = r2
  end

  test "input same arity facts" do
    r1 = FactEngine.eval_input("is_a_cat", 1, ["kcf"], %{})
    r2 = FactEngine.eval_input("is_a_dog", 1, ["lia"], r1)
    r3 = FactEngine.eval_input("is_a_cat", 1, ["chester"], r2)

    assert %{
             "is_a_cat" => %{1 => %{"kcf" => true, "chester" => true}},
             "is_a_dog" => %{1 => %{"lia" => true}}
           } = r3
  end

  test "input different arity facts" do
    r1 = FactEngine.eval_input("is_a_cat", 1, ["johnny"], %{})
    r2 = FactEngine.eval_input("are_friends", 2, ["sam", "peter"], r1)

    assert %{
             "is_a_cat" => %{1 => %{"johnny" => true}},
             "are_friends" => %{2 => %{"sam" => %{"peter" => true}}}
           } = r2
  end

  # eval_query tests

  test "eval query 1 existing 1-arity fact" do
    result =
      FactEngine.eval_query("is_a_dog", 1, ["lia"], %{"is_a_dog" => %{1 => %{"lia" => true}}})

    assert [true] = result
  end

  test "eval query 2 variable fact" do
    table = %{
      "are_friends" => %{
        2 => %{"peter" => %{"john" => true, "frank" => true}, "willy" => %{"frank" => true}}
      }
    }

    result =
      FactEngine.eval_query("are_friends", 2, [%Variable{var: "X"}, %Variable{var: "Y"}], table)

    assert [
             %{"X" => "peter", "Y" => "john"},
             %{"X" => "peter", "Y" => "frank"},
             %{"X" => "willy", "Y" => "frank"}
           ] = result
  end

  # eval_file tests

  test "query existing 1-rity function arg returns true" do
    c1 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["peter"]}
    c2 = %Command{:command => "QUERY", :fact => "is_a_cat", :arity => 1, :args => ["peter"]}
    result = FactEngine.eval_file([c1, c2], %{}, [])
    assert [true] = result
  end

  test "query non existing relation returns false" do
    c1 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["peter"]}
    c2 = %Command{:command => "QUERY", :fact => "is_a_cat", :arity => 1, :args => ["john"]}
    result = FactEngine.eval_file([c1, c2], %{}, [])
    assert [false] = result
  end

  test "multiple query responses" do
    c1 = %Command{
      :command => "INPUT",
      :fact => "are_friends",
      :arity => 2,
      :args => ["peter", "john"]
    }

    c2 = %Command{
      :command => "QUERY",
      :fact => "are_friends",
      :arity => 2,
      :args => ["peter", "john"]
    }

    c3 = %Command{
      :command => "QUERY",
      :fact => "are_friends",
      :arity => 2,
      :args => ["mike", "tim"]
    }

    c4 = %Command{
      :command => "QUERY",
      :fact => "are_friends",
      :arity => 2,
      :args => ["john", "peter"]
    }

    result = FactEngine.eval_file([c1, c2, c3, c4], %{}, [])
    assert [true, false, false] = result
  end

  test "variable 1-arity fact query" do
    c1 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["kcf"]}
    c2 = %Command{:command => "INPUT", :fact => "is_a_dog", :arity => 1, :args => ["lia"]}
    c3 = %Command{:command => "INPUT", :fact => "is_a_cat", :arity => 1, :args => ["chester"]}

    c4 = %Command{
      :command => "QUERY",
      :fact => "is_a_cat",
      :arity => 1,
      :args => [%Variable{var: "X"}]
    }

    result = FactEngine.eval_file([c1, c2, c3, c4], %{}, [])
    assert [%{"X" => "kcf"}, %{"X" => "chester"}] = result
  end

  test "nested variable query" do
    c1 = %Command{
      :command => "INPUT",
      :fact => "are_friends",
      :arity => 2,
      :args => ["peter", "john"]
    }

    c2 = %Command{
      :command => "INPUT",
      :fact => "are_friends",
      :arity => 2,
      :args => ["peter", "frank"]
    }

    c3 = %Command{
      :command => "INPUT",
      :fact => "are_friends",
      :arity => 2,
      :args => ["willy", "john"]
    }

    c4 = %Command{
      :command => "QUERY",
      :fact => "are_friends",
      :arity => 2,
      :args => [%Variable{var: "X"}, %Variable{var: "Y"}]
    }

    result = FactEngine.eval_file([c1, c2, c3, c4], %{}, [])

    assert [
             %{"X" => "peter", "Y" => "john"},
             %{"X" => "peter", "Y" => "frank"},
             %{"X" => "willy", "Y" => "frank"}
           ] = result
  end

  ## process_arg tests

  test "process_arg 1 existing" do
    table = %{
      "lia" => true
    }

    result =
      Enum.map(
        Map.keys(table),
        fn x ->
          FactEngine.process_arg(x, ["lia"], table, %{})
        end
      )

    result = List.flatten(result)
    result = FactEngine.reduce_results(result)

    assert [true] = result
  end

  test "process_arg 2 variables" do
    table = %{
      "lia" => %{"sam" => true, "frank" => true},
      "coo" => %{"lia" => true},
      "bill" => %{"sam" => true, "john" => true}
    }

    result =
      Enum.map(
        Map.keys(table),
        fn x ->
          FactEngine.process_arg(x, [%Variable{var: "X"}, %Variable{var: "Y"}], table, %{})
        end
      )

    result = List.flatten(result)
    result = FactEngine.reduce_results(result)

    _expected =
      Enum.reverse([
        %{"X" => "lia", "Y" => "sam"},
        %{"X" => "lia", "Y" => "frank"},
        %{"X" => "coo", "Y" => "lia"},
        %{"X" => "bill", "Y" => "sam"},
        %{"X" => "bill", "Y" => "john"}
      ])

    assert _expected = result
  end

  test "process_arg 1 var and 1 existing" do
    table = %{
      "lia" => %{"sam" => true, "frank" => true, "lia" => true},
      "coo" => %{"lia" => true},
      "bill" => %{"sam" => true, "john" => true}
    }

    result =
      Enum.map(
        Map.keys(table),
        fn x -> FactEngine.process_arg(x, [%Variable{var: "X"}, "sam"], table, %{}) end
      )

    result = List.flatten(result)
    result = FactEngine.reduce_results(result)
    assert [%{"X" => "lia"}, %{"X" => "bill"}] = result
  end

  test "process_arg one existing value in the middle of two vars" do
    table = %{
      "3" => %{"4" => %{"5" => true}, "10" => %{"6" => true}},
      "5" => %{"12" => %{"13" => true}}
    }

    result =
      Enum.map(
        Map.keys(table),
        fn x ->
          FactEngine.process_arg(x, [%Variable{var: "X"}, "4", %Variable{var: "Y"}], table, %{})
        end
      )

    result = List.flatten(result)
    result = FactEngine.reduce_results(result)
    assert [%{"X" => "3", "Y" => "5"}] = result
  end

  test "process_arg existing values" do
    table = %{
      "lia" => %{"sam" => true, "frank" => true, "lia" => true},
      "coo" => %{"lia" => true},
      "bill" => %{"sam" => true, "john" => true}
    }

    result =
      Enum.map(
        Map.keys(table),
        fn x -> FactEngine.process_arg(x, ["coo", "lia"], table, %{}) end
      )

    result = List.flatten(result)
    result = FactEngine.reduce_results(result)
    assert [true] = result
  end

  test "process_arg non-existing values" do
    table = %{
      "lia" => %{"sam" => true, "frank" => true, "lia" => true},
      "coo" => %{"lia" => true},
      "bill" => %{"sam" => true, "john" => true}
    }

    result =
      Enum.map(
        Map.keys(table),
        fn x -> FactEngine.process_arg(x, ["lia", "bill"], table, %{}) end
      )

    result = List.flatten(result)
    result = FactEngine.reduce_results(result)
    assert [false] = result
  end

  test "process_arg same vars" do
    table = %{
      "lia" => %{"sam" => true, "frank" => true, "lia" => true},
      "coo" => %{"lia" => true},
      "bill" => %{"sam" => true, "john" => true}
    }

    result =
      Enum.map(
        Map.keys(table),
        fn x ->
          FactEngine.process_arg(x, [%Variable{var: "X"}, %Variable{var: "X"}], table, %{})
        end
      )

    result = List.flatten(result)
    result = FactEngine.reduce_results(result)
    assert [%{"X" => "lia"}] = result
  end

  # update_dict tests

  test "update_dict deeply nested" do
    table = %{
      "lia" => %{"sam" => %{"walter" => true}}
    }

    result = FactEngine.update_dict(["lia", "sam", "john"], table)

    assert %{"lia" => %{"sam" => %{"walter" => true, "john" => true}}} = result
  end

  test "update_dict multiple keys at one level" do
    table = %{
      "peter" => %{"john" => true}
    }

    result = FactEngine.update_dict(["peter", "frank"], table)

    assert %{"peter" => %{"john" => true, "frank" => true}} = result

    result = FactEngine.update_dict(["willy", "frank"], result)

    assert %{"peter" => %{"john" => true, "frank" => true}, "willy" => %{"frank" => true}} =
             result
  end

  # reduce_result tests

  test "reduce result with all boolean returns boolean" do
    result = FactEngine.reduce_results([true, false, false, false])
    assert [true] = result
  end

  test "reduce result with all false booleans" do
    result = FactEngine.reduce_results([false, false, false, false])
    assert [false] = result
  end

  test "reduce result with a boolean" do
    result = FactEngine.reduce_results([true])
    assert [true] = result
  end

  test "reduce result, booleans and maps returns maps" do
    result = FactEngine.reduce_results([true, %{:a => "b"}, %{:b => "c"}, false])
    assert [%{b: "c"}, %{a: "b"}] = result
  end
end
