defmodule ReaderTest do
    use ExUnit.Case
    doctest FactEngine.Reader

    test "parse line returns command one arg" do
        result = FactEngine.Reader.parse_line("INPUT is_a_cat (lucy)")
        %Command{command: "INPUT", fact: "is_a_cat", arity: 1, args: ["lucy"]} = result
    end

    test "parse line returns command multiple args" do
        result = FactEngine.Reader.parse_line("QUERY are_friends (frank, sam)")
        %Command{command: "QUERY", fact: "are_friends", arity: 2} = result
    end
end

